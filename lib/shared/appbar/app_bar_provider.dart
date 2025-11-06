// lib/shared/appbar/app_bar_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _defaultAsset = 'assets/images/logo_python.png';

// 1. EL MODELO DEL ESTADO (Sin cambios)
@immutable
class AppBarState {
  final int lives;
  final int trophies;
  final int streak;
  final String languageName;
  final int languageId;
  final String languageAssetPath;
  final bool isLoading;

  const AppBarState({
    this.lives = 5,
    this.trophies = 0,
    this.streak = 0,
    this.languageName = '',
    this.languageId = 0,
    this.languageAssetPath = _defaultAsset,
    this.isLoading = true,
  });

  AppBarState copyWith({
    int? lives,
    int? trophies,
    int? streak,
    String? languageName,
    int? languageId,
    String? languageAssetPath,
    bool? isLoading,
  }) {
    return AppBarState(
      lives: lives ?? this.lives,
      trophies: trophies ?? this.trophies,
      streak: streak ?? this.streak,
      languageName: languageName ?? this.languageName,
      languageId: languageId ?? this.languageId,
      languageAssetPath: languageAssetPath ?? this.languageAssetPath,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. EL NOTIFIER (LA LÓGICA / EL CEREBRO)
class AppBarNotifier extends StateNotifier<AppBarState> {
  final SupabaseClient _supabase;

  AppBarNotifier(this._supabase)
      : super(const AppBarState(
            isLoading: true, languageAssetPath: _defaultAsset)) {
    fetchStats();
  }

  String _getAssetForLanguage(String langName) {
    switch (langName.toLowerCase().trim()) {
      case 'python':
        return 'assets/images/logo_python.png';
      case 'java':
        return 'assets/images/logo_java.png';
      case 'c':
        return 'assets/images/logo_c.png';
      default:
        return _defaultAsset;
    }
  }

  Future<void> fetchStats() async {
    // --- ¡DEBUG! ---
    debugPrint("--- AppBarNotifier: fetchStats() COMENZÓ ---");

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        // --- ¡DEBUG! ---
        debugPrint(
            "AppBarNotifier: No hay usuario. Forzando languageId: 1 (Invitado)");
        state = state.copyWith(
          isLoading: false,
          languageId: 1, // Default a Python (ID 1)
          languageName: 'Python',
          languageAssetPath: _getAssetForLanguage('Python'),
          lives: 0,
          streak: 0,
          trophies: 0,
        );
        return;
      }

      // --- CAMBIO: PASO 1 ---
      // Primero, obtenemos el lenguaje favorito del usuario.
      // Necesitamos este ID para la consulta de trofeos.
      final userData = await _supabase
          .from('usuarios')
          .select('lenguaje_favorito')
          .eq('id', user.id)
          .maybeSingle();

      final langId = (userData?['lenguaje_favorito'] ?? 1) as int;
      debugPrint("AppBarNotifier: 'lenguaje_favorito' leído es: $langId");


      // --- CAMBIO: PASO 2 ---
      // Ahora hacemos el Future.wait, PERO usando la RPC para trofeos.
      final responses = await Future.wait<dynamic>([
        // ¡USA LA NUEVA RPC! Pasa el langId que acabamos de obtener.
        _supabase.rpc(
          'get_my_language_score',
          params: {'p_language_id': langId},
        ),
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias, vidas')
            .eq('id_usuario', user.id)
            .maybeSingle(),
        // Obtenemos el nombre del lenguaje usando el langId
        _supabase
            .from('lenguaje')
            .select('nombre')
            .eq('id_lenguaje', langId)
            .single(),
      ]);

      // --- CAMBIO: PASO 3 ---
      // Procesamos las respuestas del NUEVO Future.wait
      
      // Respuesta 0: Trofeos (la RPC devuelve un solo número)
      final totalTrofeos = (responses[0] as int? ?? 0);

      // Respuesta 1: Vidas y Racha (sin cambios)
      final statsResponseData = responses[1] as Map<String, dynamic>?;
      final racha = statsResponseData?['racha_dias'] ?? 0;
      final vidas = statsResponseData?['vidas'] ?? 5;

      // Respuesta 2: Nombre del Lenguaje (sin cambios)
      final langResponse = responses[2] as Map<String, dynamic>;
      final langName = (langResponse['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      // --- ¡DEBUG! ---
      debugPrint(
          "AppBarNotifier: PONIENDO ESTADO FINAL -> languageId: $langId, trofeos: $totalTrofeos, isLoading: false");

      state = state.copyWith(
        lives: vidas,
        trophies: totalTrofeos, // <-- ¡Este número AHORA es el correcto!
        streak: racha,
        languageName: langName,
        languageId: langId,
        languageAssetPath: langAsset,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      // --- ¡DEBUG! ---
      debugPrint(
          "--- AppBarNotifier: ¡ERROR! CAYÓ EN CATCH. Forzando languageId: 1 ---");
      debugPrint('Error en AppBarNotifier: $e');
      debugPrint('Stacktrace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        languageAssetPath: _getAssetForLanguage('Python'),
        languageId: 1,
        languageName: 'Python',
        lives: 0,
        streak: 0,
        trophies: 0,
      );
    }
  }

  // --- CAMBIO: PASO 4 ---
  // Esta función ahora debe ser 'async' y debe llamar a fetchStats()
  // para recargar TODO (incluyendo los trofeos correctos).
  Future<void> updateLanguage(String newName, int newId) async {
    // 1. Actualiza el estado local INMEDIATAMENTE para que la UI se sienta rápida
    //    (Mostraremos 0 trofeos brevemente mientras se cargan los nuevos).
    final newAsset = _getAssetForLanguage(newName);
    state = state.copyWith(
      languageName: newName,
      languageId: newId,
      languageAssetPath: newAsset,
      trophies: 0, // Opcional: mostrar 0 mientras carga
      isLoading: true, // Opcional: mostrar un loader
    );
    
    // 2. IMPORTANTE: Actualiza el 'lenguaje_favorito' en la base de datos.
    //    Esto es crucial para que el próximo fetchStats() funcione.
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('usuarios')
            .update({'lenguaje_favorito': newId})
            .eq('id', user.id);
      } catch (e) {
          debugPrint("Error al actualizar lenguaje_favorito: $e");
          // Manejar error si es necesario
      }
    }

    // 3. Llama a fetchStats() OTRA VEZ.
    //    Esta vez, leerá el 'newId' de la base de datos (que acabamos de guardar)
    //    y llamará a la RPC con ese 'newId', obteniendo los trofeos
    //    correctos para el *nuevo* lenguaje.
    await fetchStats();
  }
}

// 3. PROVIDER DEL NOTIFIER (Sin cambios)
final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarState>((ref) {
  final supabase = Supabase.instance.client;
  return AppBarNotifier(supabase);
});

// --- 4. PROVIDER DE REALTIME (Sin cambios) ---
// ¡Buenas noticias! Tu código de realtime (abajo) ya es perfecto.
// Como todos tus listeners simplemente llaman a 'ref.read(appBarProvider.notifier).fetchStats()',
// y acabamos de arreglar 'fetchStats()', tus listeners ahora
// refrescarán el estado con la lógica correcta automáticamente.
// No necesitas cambiar NADA aquí.
final appBarRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // 1. Canal para racha/Vidas
  final statsChannel = supabase.channel('public:estadistica_usuario:appbar');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'estadistica_usuario',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      debugPrint(
          "CAMBIO EN ESTADISTICAS (RACHA/VIDAS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // 2. Canal para trofeos
  final trofeosChannel = supabase.channel('public:intento_reto:appbar');
  trofeosChannel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'intento_reto',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      debugPrint(
          "CAMBIO EN INTENTOS (TROFEOS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // 3. Canal para el lenguaje (tabla 'usuarios')
  final userChannel = supabase.channel('public:usuarios:appbar');
  userChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'usuarios',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: userId,
    ),
    callback: (payload) {
      debugPrint("--- CAMBIO DETECTADO EN TABLA 'usuarios' ---");
      debugPrint("Payload (new): ${payload.newRecord}");
      debugPrint("Refrescando AppBar AHORA.");

      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // Limpiar canales
  ref.onDispose(() {
    supabase.removeChannel(statsChannel);
    supabase.removeChannel(trofeosChannel);
    supabase.removeChannel(userChannel);
  });
});