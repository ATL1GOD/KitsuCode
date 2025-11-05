// lib/shared/appbar/app_bar_provider.dart
import 'package:flutter/foundation.dart'; // <-- ¡IMPORTADO PARA debugPrint!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asumiré que logo_python.png existe y es tu asset por defecto
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
    this.lives = 5, // <-- CAMBIO: Valor por defecto 5 (en lugar de 0)
    this.trophies = 0,
    this.streak = 0,
    this.languageName = '', // ¡Cambiado a '' para que el fallback funcione!
    this.languageId = 0,
    this.languageAssetPath = _defaultAsset,
    this.isLoading = true,
  });

  // Método "copyWith" (sin cambios)
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

  // Helper (corregido con .trim() y 'c')
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
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // (Usamos .maybeSingle() para evitar errores si el usuario es nuevo)
      final responses = await Future.wait<dynamic>([
        // 0: Trofeos (Devuelve Lista)
        _supabase
            .from('intento_reto')
            .select('experiencia_obtenida')
            .eq('id_usuario', user.id),
            
        // 1: Racha Y VIDAS (¡CAMBIO AQUÍ!)
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias, vidas') // <-- ¡AÑADIDO 'vidas'!
            .eq('id_usuario', user.id)
            .maybeSingle(), 

        // 2: Lenguaje ID (Devuelve Map?)
        _supabase
            .from('usuarios')
            .select('lenguaje_favorito')
            .eq('id', user.id)
            .maybeSingle(), 
      ]);

      // 🏆 Trofeos (experiencia total)
      // (Corregido para castear 'responses[0]' a List)
      final xpResponseData = responses[0] as List;
      int totalTrofeos = 0;
      for (var row in xpResponseData) {
        if (row is Map<String, dynamic>) {
          totalTrofeos += (row['experiencia_obtenida'] ?? 0) as int;
        }
      }

      // 🔥 Racha y Vidas (¡CAMBIO AQUÍ!)
      final statsResponseData = responses[1] as Map<String, dynamic>?;
      final racha = statsResponseData?['racha_dias'] ?? 0;
      final vidas = statsResponseData?['vidas'] ?? 5; // <-- ¡LEEMOS LAS VIDAS!

      // 🌐 Lenguaje ID
      final userData = responses[2] as Map<String, dynamic>?;
      final langId = (userData?['lenguaje_favorito'] ?? 1) as int; 

      final langResponse = await _supabase
          .from('lenguaje')
          .select('nombre')
          .eq('id_lenguaje', langId)
          .single();

      final langName = (langResponse['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      state = state.copyWith(
        lives: vidas, // <-- ¡VIDAS ACTUALIZADAS!
        trophies: totalTrofeos, 
        streak: racha,
        languageName: langName,
        languageId: langId,
        languageAssetPath: langAsset,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Error en AppBarNotifier: $e');
      debugPrint('Stacktrace: $stackTrace');
      state =
          state.copyWith(isLoading: false, languageAssetPath: _defaultAsset);
    }
  }

  // void decrementLives() {
  //   if (state.lives > 0) {
  //     state = state.copyWith(lives: state.lives - 1);
  //   }
  // }

  void updateLanguage(String newName, int newId) {
    final newAsset = _getAssetForLanguage(newName);
    state = state.copyWith(
        languageName: newName,
        languageId: newId,
        languageAssetPath: newAsset);
  }
}

// 3. EL PROVIDER DEL NOTIFIER (Sin cambios)
final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarState>((ref) {
  final supabase = Supabase.instance.client;
  return AppBarNotifier(supabase);
});


// --- 4. ¡EL PROVIDER DE REALTIME (CORREGIDO)! ---
final appBarRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // 1. Canal para cambios en la racha (y Vidas)
  final statsChannel = supabase.channel('public:estadistica_usuario:appbar');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'estadistica_usuario',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      // --- ¡ARREGLADO! ---
      debugPrint("CAMBIO EN ESTADISTICAS (RACHA/VIDAS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // 2. Canal para cambios en los trofeos
  final trofeosChannel = supabase.channel('public:intento_reto:appbar');
  trofeosChannel.onPostgresChanges(
    event: PostgresChangeEvent.all, // INSERT, UPDATE, DELETE
    schema: 'public',
    table: 'intento_reto',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      // --- ¡ARREGLADO! ---
      debugPrint("CAMBIO EN INTENTOS (TROFEOS) DETECTADO -> Refrescando AppBar");
      ref.read(appBarProvider.notifier).fetchStats();
    },
  ).subscribe();

  // Limpiar los canales cuando el provider sea desechado
  ref.onDispose(() {
    supabase.removeChannel(statsChannel);
    supabase.removeChannel(trofeosChannel);
  });
});