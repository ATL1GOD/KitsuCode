import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kitsucode/shared/appbar/app_bar_provider.dart'; // 🔥 NUEVO import

// Estado para tracking de completitud de lenguajes

class LanguageCompletionState {
  final String currentLanguage;

  final List<String> unlockedLanguages;

  final bool hasCompletedLanguage;

  final bool canUnlockNewLanguage; // Si este lenguaje puede desbloquear otro

  final int totalLevelsInLanguage;

  final int completedLevelsInLanguage;

  LanguageCompletionState({
    required this.currentLanguage,

    required this.unlockedLanguages,

    this.hasCompletedLanguage = false,

    this.canUnlockNewLanguage = true, // Por defecto sí puede

    this.totalLevelsInLanguage = 0,

    this.completedLevelsInLanguage = 0,
  });

  LanguageCompletionState copyWith({
    String? currentLanguage,

    List<String>? unlockedLanguages,

    bool? hasCompletedLanguage,

    bool? canUnlockNewLanguage,

    int? totalLevelsInLanguage,

    int? completedLevelsInLanguage,
  }) {
    return LanguageCompletionState(
      currentLanguage: currentLanguage ?? this.currentLanguage,

      unlockedLanguages: unlockedLanguages ?? this.unlockedLanguages,

      hasCompletedLanguage: hasCompletedLanguage ?? this.hasCompletedLanguage,

      canUnlockNewLanguage: canUnlockNewLanguage ?? this.canUnlockNewLanguage,

      totalLevelsInLanguage:
          totalLevelsInLanguage ?? this.totalLevelsInLanguage,

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

  final Ref _ref; // 🔥 NUEVO: Necesitamos el ref para actualizar el AppBar

  LanguageCompletionNotifier(this._supabase, this._ref)
    : super(
        LanguageCompletionState(currentLanguage: '', unlockedLanguages: []),
      );

  /// Verifica si el usuario completó un lenguaje (Estrategia Híbrida)

  Future<void> checkLanguageCompletion(String userId) async {
    try {
      // 1. Obtener el lenguaje favorito actual y arrays en UNA sola consulta

      final userResponse = await _supabase
          .from('usuarios')
          .select('''

            lenguaje_favorito,

            lenguajes_completados,

            lenguajes_usados_desbloqueo,

            lenguaje:lenguaje_favorito ( nombre )

          ''')
          .eq('id', userId)
          .single();

      final langData = userResponse['lenguaje'] as Map<String, dynamic>?;

      final currentLanguageName =
          (langData?['nombre'] as String?)?.trim() ?? '';

      if (currentLanguageName.isEmpty) return;

      final normalizedCurrentLang = currentLanguageName.toLowerCase();

      final currentLangId = userResponse['lenguaje_favorito'] as int;

      // 2. Procesar Arrays

      final completadosList = List<String>.from(
        (userResponse['lenguajes_completados'] as List? ?? []).map(
          (e) => e.toString().trim().toLowerCase(),
        ),
      );

      final usadosList = List<String>.from(
        (userResponse['lenguajes_usados_desbloqueo'] as List? ?? []).map(
          (e) => e.toString().trim().toLowerCase(),
        ),
      );

      // 3. Lógica de Verificación

      bool isCompleted = completadosList.contains(normalizedCurrentLang);

      // --- AQUÍ ESTÁ LA SOLUCIÓN ---

      // Si la BD dice que NO está completado, verificamos manualmente contando niveles.

      // Esto arregla el caso donde el Trigger SQL no existe o falló.

      if (!isCompleted) {
        // Verificación manual (Dart contando niveles)

        final manualCheck = await _verifyManuallyIfCompleted(
          userId,
          currentLangId,
        );

        if (manualCheck) {
          isCompleted = true;

          // ¡Importante! Actualizamos la BD para que quede guardado

          await _addToCompletedLanguages(userId, normalizedCurrentLang);

          // Actualizamos la lista local para que la lógica siguiente funcione

          completadosList.add(normalizedCurrentLang);
        }
      }

      // -----------------------------

      // 4. Determinar desbloqueo

      final hasBeenUsed = usadosList.contains(normalizedCurrentLang);

      final canUnlock = isCompleted && !hasBeenUsed;

      // 5. Obtener desbloqueados

      final unlockedLanguages = await _getUnlockedLanguages(userId);

      state = state.copyWith(
        currentLanguage: currentLanguageName,

        unlockedLanguages: unlockedLanguages,

        hasCompletedLanguage: isCompleted,

        canUnlockNewLanguage: canUnlock,
      );
    } catch (e) {
      debugPrint('Error checkLanguageCompletion: $e');
    }
  }

  /// Cuenta niveles manualmente: Es la "red de seguridad"

  Future<bool> _verifyManuallyIfCompleted(String userId, int langId) async {
    try {
      // A. Obtener secciones del lenguaje

      final sectionsResponse = await _supabase
          .from('secciones')
          .select('id_seccion')
          .eq('id_lenguaje', langId);

      final sectionIds = sectionsResponse
          .map((s) => s['id_seccion'] as int)
          .toList();

      if (sectionIds.isEmpty) return false;

      // B. Obtener total de niveles de esas secciones

      final levelsResponse = await _supabase
          .from('niveles')
          .select('id_nivel')
          .inFilter('id_seccion', sectionIds);

      final totalLevels = levelsResponse.length;

      if (totalLevels == 0) return false;

      final levelIds = levelsResponse.map((l) => l['id_nivel'] as int).toList();

      // C. Contar cuántos de esos niveles ha completado el usuario

      final completedResponse = await _supabase
          .from('progreso_usuario')
          .select('id_nivel')
          .eq('id_usuario', userId)
          .inFilter('id_nivel', levelIds);

      final completedLevels = completedResponse.length;

      // D. Si completó todos (o más), es true

      return completedLevels >= totalLevels;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addToCompletedLanguages(
    String userId,
    String languageName,
  ) async {
    try {
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_completados')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return;

      final currentList = List<String>.from(
        userResponse['lenguajes_completados'] ?? [],
      );

      final normalized = languageName.trim().toLowerCase();

      if (!currentList.contains(normalized)) {
        currentList.add(normalized);

        await _supabase
            .from('usuarios')
            .update({'lenguajes_completados': currentList})
            .eq('id', userId);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _addToSelectedLanguages(
    String userId,
    String languageName,
  ) async {
    try {
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_seleccionados')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return;

      final currentList = List<String>.from(
        userResponse['lenguajes_seleccionados'] ?? [],
      );

      final normalized = languageName.trim().toLowerCase();

      if (!currentList.contains(normalized)) {
        currentList.add(normalized);

        await _supabase
            .from('usuarios')
            .update({'lenguajes_seleccionados': currentList})
            .eq('id', userId);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<List<String>> _getUnlockedLanguages(String userId) async {
    try {
      final response =
          await _supabase.rpc(
                'get_unlocked_languages',
                params: {'user_id': userId},
              )
              as List;

      return response
          .map((row) => (row['language_name'] as String).trim().toLowerCase())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualiza el lenguaje favorito del usuario

  Future<void> updateFavoriteLanguage(
    String userId,

    String languageName, {
    String? previousLanguage,
  }) async {
    try {
      final normalizedName = languageName.trim().toLowerCase();

      debugPrint('🔥 [updateFavoriteLanguage] Iniciando...');
      debugPrint('   - Usuario: $userId');
      debugPrint('   - Nuevo lenguaje: $languageName');
      debugPrint('   - Lenguaje anterior: $previousLanguage');

      final languageResponse = await _supabase
          .from('lenguaje')
          .select('id_lenguaje, nombre')
          .ilike('nombre', normalizedName)
          .maybeSingle();

      if (languageResponse == null) {
        throw Exception('Lenguaje no encontrado: $languageName');
      }

      final languageId = languageResponse['id_lenguaje'] as int;

      final exactLanguageName = (languageResponse['nombre'] as String).trim();

      debugPrint('   - ID del nuevo lenguaje: $languageId');
      debugPrint('   - Nombre exacto: $exactLanguageName');

      // 1. Actualizar BD

      await _supabase
          .from('usuarios')
          .update({'lenguaje_favorito': languageId})
          .eq('id', userId);

      debugPrint('   ✅ BD actualizada');

      // 2. Marcar lenguaje anterior como usado

      if (previousLanguage != null && previousLanguage.isNotEmpty) {
        await _markLanguageAsUsedForUnlock(
          userId,
          previousLanguage.trim().toLowerCase(),
        );

        debugPrint('   ✅ Lenguaje anterior marcado como usado');
      }

      // 3. Agregar a lenguajes seleccionados

      await _addToSelectedLanguages(userId, normalizedName);

      debugPrint('   ✅ Agregado a lenguajes seleccionados');

      // 4. Actualizar estado local

      state = state.copyWith(currentLanguage: exactLanguageName);

      debugPrint('   ✅ Estado local actualizado');

      // 🔥 5. CRÍTICO: Actualizar AppBar con los trofeos del nuevo lenguaje

      // Importamos el appBarProvider desde app_bar_provider.dart

      debugPrint('   🎯 Llamando a appBarProvider.updateLanguage...');
      await _ref
          .read(appBarProvider.notifier)
          .updateLanguage(exactLanguageName, languageId);

      debugPrint('   ✅ AppBar actualizado');

      debugPrint('🔥 [updateFavoriteLanguage] ¡Completado exitosamente!');
    } catch (e) {
      debugPrint('❌ [updateFavoriteLanguage] Error: $e');

      rethrow;
    }
  }

  Future<void> _markLanguageAsUsedForUnlock(
    String userId,
    String languageName,
  ) async {
    try {
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_usados_desbloqueo')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return;

      final currentList = List<String>.from(
        userResponse['lenguajes_usados_desbloqueo'] ?? [],
      );

      final normalized = languageName.trim().toLowerCase();

      if (!currentList.contains(normalized)) {
        currentList.add(normalized);

        await _supabase
            .from('usuarios')
            .update({'lenguajes_usados_desbloqueo': currentList})
            .eq('id', userId);
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void resetCompletionState() {
    state = state.copyWith(hasCompletedLanguage: false);
  }
}

final languageCompletionProvider =
    StateNotifierProvider<LanguageCompletionNotifier, LanguageCompletionState>(
      (ref) => LanguageCompletionNotifier(
        Supabase.instance.client,
        ref,
      ), // 🔥 Pasamos el ref
    );
