// lib/features/challenge/provider/language_completion_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Estado para tracking de completitud de lenguajes
class LanguageCompletionState {
  final String currentLanguage;
  final List<String> unlockedLanguages;
  final bool hasCompletedLanguage;
  final int totalLevelsInLanguage;
  final int completedLevelsInLanguage;

  LanguageCompletionState({
    required this.currentLanguage,
    required this.unlockedLanguages,
    this.hasCompletedLanguage = false,
    this.totalLevelsInLanguage = 0,
    this.completedLevelsInLanguage = 0,
  });

  LanguageCompletionState copyWith({
    String? currentLanguage,
    List<String>? unlockedLanguages,
    bool? hasCompletedLanguage,
    int? totalLevelsInLanguage,
    int? completedLevelsInLanguage,
  }) {
    return LanguageCompletionState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      unlockedLanguages: unlockedLanguages ?? this.unlockedLanguages,
      hasCompletedLanguage: hasCompletedLanguage ?? this.hasCompletedLanguage,
      totalLevelsInLanguage: totalLevelsInLanguage ?? this.totalLevelsInLanguage,
      completedLevelsInLanguage:
          completedLevelsInLanguage ?? this.completedLevelsInLanguage,
    );
  }

  double get progressPercentage {
    if (totalLevelsInLanguage == 0) return 0.0;
    return completedLevelsInLanguage / totalLevelsInLanguage;
  }

  bool get isLanguageCompleted => progressPercentage >= 1.0;
}

class LanguageCompletionNotifier
    extends StateNotifier<LanguageCompletionState> {
  final SupabaseClient _supabase;

  LanguageCompletionNotifier(this._supabase)
      : super(LanguageCompletionState(
          currentLanguage: '',
          unlockedLanguages: [],
        ));

  /// Verifica si el usuario completó un lenguaje
  Future<void> checkLanguageCompletion(String userId) async {
    try {
      // 1. Obtener el lenguaje favorito actual del usuario
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguaje_favorito, lenguaje(nombre)')
          .eq('id', userId)
          .single();

      final currentLanguageId = userResponse['lenguaje_favorito'] as int?;
      if (currentLanguageId == null) return;

      final currentLanguageName =
          userResponse['lenguaje']['nombre'] as String;

      // 2. Obtener todos los niveles del lenguaje actual
      final sectionsResponse = await _supabase
          .from('secciones')
          .select('id_seccion')
          .eq('id_lenguaje', currentLanguageId);

      final sectionIds =
          sectionsResponse.map((s) => s['id_seccion'] as int).toList();

      if (sectionIds.isEmpty) return;

      final levelsResponse = await _supabase
          .from('niveles')
          .select('id_nivel')
          .inFilter('id_seccion', sectionIds);

      final totalLevels = levelsResponse.length;

      // 3. Obtener niveles completados por el usuario
      final completedResponse = await _supabase
          .from('progreso_usuario')
          .select('id_nivel')
          .eq('id_usuario', userId)
          .inFilter(
              'id_nivel', levelsResponse.map((l) => l['id_nivel']).toList());

      final completedLevels = completedResponse.length;

      // 4. Verificar si completó todos los niveles
      final hasCompleted = completedLevels >= totalLevels && totalLevels > 0;

      // 5. Obtener lenguajes desbloqueados
      // Por defecto, el primer lenguaje siempre está desbloqueado
      // Los siguientes se desbloquean al completar el anterior
      final unlockedLanguages = await _getUnlockedLanguages(userId);

      state = state.copyWith(
        currentLanguage: currentLanguageName,
        unlockedLanguages: unlockedLanguages,
        hasCompletedLanguage: hasCompleted,
        totalLevelsInLanguage: totalLevels,
        completedLevelsInLanguage: completedLevels,
      );
    } catch (e) {
      print('Error checking language completion: $e');
    }
  }

  /// Obtiene la lista de lenguajes desbloqueados para el usuario
  Future<List<String>> _getUnlockedLanguages(String userId) async {
    try {
      // Obtener todos los lenguajes
      final allLanguagesResponse =
          await _supabase.from('lenguaje').select('id_lenguaje, nombre');

      final allLanguages = allLanguagesResponse
          .map((lang) => {
                'id': lang['id_lenguaje'] as int,
                'name': lang['nombre'] as String,
              })
          .toList();

      final List<String> unlocked = [];

      // El primer lenguaje siempre está desbloqueado
      if (allLanguages.isNotEmpty) {
        unlocked.add(allLanguages[0]['name'] as String);
      }

      // Verificar cada lenguaje subsecuente
      for (int i = 0; i < allLanguages.length; i++) {
        final lang = allLanguages[i];
        final langId = lang['id'] as int;
        final langName = lang['name'] as String;

        // Si ya está en la lista, continuar
        if (unlocked.contains(langName)) continue;

        // Verificar si completó todos los niveles de este lenguaje
        final sectionsResponse = await _supabase
            .from('secciones')
            .select('id_seccion')
            .eq('id_lenguaje', langId);

        final sectionIds =
            sectionsResponse.map((s) => s['id_seccion'] as int).toList();

        if (sectionIds.isEmpty) continue;

        final levelsResponse = await _supabase
            .from('niveles')
            .select('id_nivel')
            .inFilter('id_seccion', sectionIds);

        final totalLevels = levelsResponse.length;

        final completedResponse = await _supabase
            .from('progreso_usuario')
            .select('id_nivel')
            .eq('id_usuario', userId)
            .inFilter(
                'id_nivel', levelsResponse.map((l) => l['id_nivel']).toList());

        final completedLevels = completedResponse.length;

        // Si completó todos los niveles, el lenguaje está desbloqueado
        if (completedLevels >= totalLevels && totalLevels > 0) {
          unlocked.add(langName);
        }
      }

      return unlocked;
    } catch (e) {
      print('Error getting unlocked languages: $e');
      return [];
    }
  }

  /// Actualiza el lenguaje favorito del usuario
  Future<void> updateFavoriteLanguage(String userId, String languageName) async {
    try {
      // Obtener el ID del lenguaje
      final languageResponse = await _supabase
          .from('lenguaje')
          .select('id_lenguaje')
          .eq('nombre', languageName)
          .single();

      final languageId = languageResponse['id_lenguaje'] as int;

      // Actualizar en la BD
      await _supabase
          .from('usuarios')
          .update({'lenguaje_favorito': languageId}).eq('id', userId);

      // Actualizar el estado
      state = state.copyWith(currentLanguage: languageName);
    } catch (e) {
      print('Error updating favorite language: $e');
      rethrow;
    }
  }

  /// Resetea el estado de completitud
  void resetCompletionState() {
    state = state.copyWith(hasCompletedLanguage: false);
  }
}

// Provider
final languageCompletionProvider =
    StateNotifierProvider<LanguageCompletionNotifier, LanguageCompletionState>(
  (ref) => LanguageCompletionNotifier(Supabase.instance.client),
);