// lib/shared/appbar/app_bar_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _defaultAsset = 'assets/images/logo_python.png';

// 1. EL MODELO DEL ESTADO (Sin cambios)
@immutable
class AppBarState {
  // ... (tu estado sin cambios) ...
  final int lives;
  final int trophies;
  final int streak;
  final String languageName;
  final int languageId;
  final String languageAssetPath;
  final bool isLoading;

  const AppBarState({
    this.lives = 0,
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

  // --- ¡CAMBIO 1: Añadido .trim() al helper! ---
  String _getAssetForLanguage(String langName) {
    // Usamos .trim() para quitar espacios
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

      final responses = await Future.wait<dynamic>([
        // ... (tus 3 'awaits' de supabase) ...
        _supabase
            .from('intento_reto')
            .select('experiencia_obtenida')
            .eq('id_usuario', user.id),
        _supabase
            .from('estadistica_usuario')
            .select('racha_dias')
            .eq('id_usuario', user.id)
            .single(),
        _supabase
            .from('usuarios')
            .select('lenguaje_favorito')
            .eq('id', user.id)
            .single(),
      ]);

      // 🏆 Trofeos (sin cambios)
      final xpResponseData = (responses[0] as PostgrestResponse).data as List;
      int totalTrofeos = 0;
      for (var row in xpResponseData) {
        totalTrofeos += (row['experiencia_obtenida'] ?? 0) as int;
      }

      // 🔥 Racha (sin cambios)
      final statsResponseData = responses[1] as Map<String, dynamic>;
      final racha = statsResponseData['racha_dias'] ?? 0;

      // 🌐 Lenguaje ID (sin cambios)
      final userData = responses[2] as Map<String, dynamic>;
      final langId = (userData['lenguaje_favorito'] ?? 1) as int; 

      final langResponse = await _supabase
          .from('lenguaje')
          .select('nombre')
          .eq('id_lenguaje', langId)
          .single();

      // --- ¡CAMBIO 2: Añadido .trim() al resultado de la DB! ---
      final langName = (langResponse['nombre'] as String).trim();
      final langAsset = _getAssetForLanguage(langName);

      // Actualizamos el estado
      state = state.copyWith(
        lives: 5, // Temporal
        trophies: totalTrofeos,
        streak: racha,
        languageName: langName, // (ej: "Java", ya sin espacios)
        languageId: langId,
        languageAssetPath: langAsset, // (ej: "assets/images/logo_java.png")
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Error en AppBarNotifier: $e');
      debugPrint('Stacktrace: $stackTrace');
      state =
          state.copyWith(isLoading: false, languageAssetPath: _defaultAsset);
    }
  }

  // (Tu función decrementLives - sin cambios)
  void decrementLives() {
    if (state.lives > 0) {
      state = state.copyWith(lives: state.lives - 1);
    }
  }

  // (Tu función updateLanguage - sin cambios)
  void updateLanguage(String newName, int newId) {
    final newAsset = _getAssetForLanguage(newName);
    state = state.copyWith(
        languageName: newName,
        languageId: newId,
        languageAssetPath: newAsset);
  }
}

// EL PROVIDER (Sin cambios)
final appBarProvider = StateNotifierProvider<AppBarNotifier, AppBarState>((ref) {
  final supabase = Supabase.instance.client;
  return AppBarNotifier(supabase);
});