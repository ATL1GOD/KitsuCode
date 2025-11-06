// lib/shared/appbar/app_bar_provider.dart
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- (EL CÓDIGO ANTERIOR NO CAMBIA) ---
// ... (AppBarState, AppBarNotifier, y appBarProvider siguen igual) ...

const String _defaultAsset = 'assets/images/logo_python.png';

// 1. EL MODELO DEL ESTADO (LOS DATOS)
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
        debugPrint("AppBarNotifier: No hay usuario. Forzando languageId: 1 (Invitado)");
        state = state.copyWith(
          isLoading: false,
          languageId: 1, 
          languageName: 'Python',
          languageAssetPath: _getAssetForLanguage('Python'),
          lives: 0,
          streak: 0,
          trophies: 0,
        );
        return;
      }

      final responses = await Future.wait<dynamic>([
        _supabase
            .from('intento_reto')
            .select('experiencia_obtenida')
            .eq('id_usuario', user.id),
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias, vidas')
            .eq('id_usuario', user.id)
            .maybeSingle(),
        _supabase
            .from('usuarios')
            .select('lenguaje_favorito')
            .eq('id', user.id)
            .maybeSingle(),
      ]);

      final xpResponseData = responses[0] as List;
      int totalTrofeos = 0;
      for (var row in xpResponseData) {
        if (row is Map<String, dynamic>) {
          totalTrofeos += (row['experiencia_obtenida'] ?? 0) as int;
        }
      }
      final statsResponseData = responses[1] as Map<String, dynamic>?;
      final racha = statsResponseData?['racha_dias'] ?? 0;
      final vidas = statsResponseData?['vidas'] ?? 5;

      final userData = responses[2] as Map<String, dynamic>?;
      final langId = (userData?['lenguaje_favorito'] ?? 1) as int; 
      
      // --- ¡DEBUG! ---
      debugPrint("AppBarNotifier: 'lenguaje_favorito' leído de Supabase es: $langId");

      final langResponse = await _supabase
          .from('lenguaje')
          .select('nombre')
          .eq('id_lenguaje', langId)
          .single();

      final langName = (langResponse['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      // --- ¡DEBUG! ---
      debugPrint("AppBarNotifier: PONIENDO ESTADO FINAL -> languageId: $langId, isLoading: false");

      state = state.copyWith(
        lives: vidas,
        trophies: totalTrofeos,
        streak: racha,
        languageName: langName,
        languageId: langId,
        languageAssetPath: langAsset,
        isLoading: false,
      );

    } catch (e, stackTrace) {
      // --- ¡DEBUG! ---
      debugPrint("--- AppBarNotifier: ¡ERROR! CAYÓ EN CATCH. Forzando languageId: 1 ---");
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

  void updateLanguage(String newName, int newId) {
    final newAsset = _getAssetForLanguage(newName);
    state = state.copyWith(
        languageName: newName,
        languageId: newId,
        languageAssetPath: newAsset);
  }
}

// 3. PROVIDER DEL NOTIFIER (Sin cambios)
final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarState>((ref) {
  final supabase = Supabase.instance.client;
  return AppBarNotifier(supabase);
});


// --- 4. ¡EL PROVIDER DE REALTIME (CON PRUEBA DE DEPURACIÓN)! ---
final appBarRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // 1. Canal para racha/Vidas (Sin cambios)
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
      debugPrint("CAMBIO EN ESTADISTICAS (RACHA/VIDAS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // 2. Canal para trofeos (Sin cambios)
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
      debugPrint("CAMBIO EN INTENTOS (TROFEOS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // --- ¡CAMBIO GRANDE AQUÍ! ---
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
      // --- ¡PRUEBA DE DEPURACIÓN! ---
      // Hemos quitado la comprobación de 'oldLang != newLang'.
      // Ahora CUALQUIER cambio en la fila 'usuarios' (como cambiar 
      // 'nombre_perfil') debería disparar este log y un refresco.
      
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