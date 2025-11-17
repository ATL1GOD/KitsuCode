// lib/features/challenge/provider/language_completion_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Estado para tracking de completitud de lenguajes
class LanguageCompletionState {
  final String currentLanguage;
  final List<String> unlockedLanguages;
  final bool hasCompletedLanguage;
  final bool canUnlockNewLanguage; // 🆕 Si este lenguaje puede desbloquear otro
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
      debugPrint('🔍 Verificando completitud de lenguaje para user: $userId');
      
      // 1. Obtener el lenguaje favorito actual del usuario
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguaje_favorito, lenguaje(nombre)')
          .eq('id', userId)
          .single();

      final currentLanguageId = userResponse['lenguaje_favorito'] as int?;
      if (currentLanguageId == null) {
        debugPrint('⚠️ Usuario no tiene lenguaje favorito');
        return;
      }

      final currentLanguageName = userResponse['lenguaje']['nombre'] as String;
      debugPrint('📚 Lenguaje actual: $currentLanguageName (ID: $currentLanguageId)');

      // 2. Obtener todas las secciones del lenguaje
      final sectionsResponse = await _supabase
          .from('secciones')
          .select('id_seccion')
          .eq('id_lenguaje', currentLanguageId);

      final sectionIds = sectionsResponse.map((s) => s['id_seccion'] as int).toList();
      debugPrint('📂 Secciones encontradas: ${sectionIds.length}');

      if (sectionIds.isEmpty) {
        debugPrint('⚠️ No hay secciones para este lenguaje');
        return;
      }

      // 3. Obtener todos los niveles de esas secciones
      final levelsResponse = await _supabase
          .from('niveles')
          .select('id_nivel')
          .inFilter('id_seccion', sectionIds);

      final totalLevels = levelsResponse.length;
      final levelIds = levelsResponse.map((l) => l['id_nivel'] as int).toList();
      debugPrint('📊 Total de niveles: $totalLevels');

      if (totalLevels == 0) {
        debugPrint('⚠️ No hay niveles en este lenguaje');
        return;
      }

      // 4. Obtener niveles completados por el usuario
      final completedResponse = await _supabase
          .from('progreso_usuario')
          .select('id_nivel')
          .eq('id_usuario', userId)
          .inFilter('id_nivel', levelIds);

      final completedLevels = completedResponse.length;
      debugPrint('✅ Niveles completados: $completedLevels/$totalLevels');

      // 5. Verificar si completó todos los niveles
      final hasCompleted = completedLevels >= totalLevels && totalLevels > 0;
      debugPrint(hasCompleted ? '🎉 ¡LENGUAJE COMPLETADO!' : '📖 Lenguaje en progreso');

      // 🆕 Verificar si este lenguaje ya fue usado para desbloquear otro
      final canUnlock = await _canLanguageUnlockAnother(userId, currentLanguageName.trim().toLowerCase());
      debugPrint(canUnlock 
        ? '🎁 Este lenguaje PUEDE desbloquear otro' 
        : '🚫 Este lenguaje YA desbloqueó otro lenguaje');

      // 🔥 CRÍTICO: Solo mostrar celebración si PUEDE desbloquear
      // Si ya usó este lenguaje, NO mostrar celebración aunque complete niveles
      final shouldCelebrate = hasCompleted && canUnlock;
      debugPrint(shouldCelebrate 
        ? '🎊 Mostrar celebración y selección' 
        : '🏠 Volver al home normalmente');

      // 🆕 Si completó el lenguaje, agregarlo a lenguajes_completados
      if (hasCompleted) {
        await _addToCompletedLanguages(userId, currentLanguageName.trim().toLowerCase());
      }

      // 6. Obtener lenguajes desbloqueados
      final unlockedLanguages = await _getUnlockedLanguages(userId);
      debugPrint('🔓 Lenguajes desbloqueados: ${unlockedLanguages.join(", ")}');

      state = state.copyWith(
        currentLanguage: currentLanguageName.trim(), // Limpiar espacios
        unlockedLanguages: unlockedLanguages,
        hasCompletedLanguage: shouldCelebrate, // 🔥 CAMBIO: Solo true si puede desbloquear
        canUnlockNewLanguage: canUnlock,
        totalLevelsInLanguage: totalLevels,
        completedLevelsInLanguage: completedLevels,
      );
      
      debugPrint('✨ Estado actualizado correctamente');
    } catch (e) {
      debugPrint('❌ Error checking language completion: $e');
      rethrow;
    }
  }

  /// Verifica si un lenguaje puede desbloquear otro lenguaje
  /// Retorna false si el lenguaje ya fue usado para desbloquear
  Future<bool> _canLanguageUnlockAnother(String userId, String languageName) async {
    try {
      debugPrint('🔍 Verificando si $languageName puede desbloquear...');
      
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_usados_desbloqueo')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ Usuario no encontrado');
        return false;
      }

      final usadosList = userResponse['lenguajes_usados_desbloqueo'] as List?;
      final usados = usadosList?.map((e) => e.toString().trim().toLowerCase()).toList() ?? [];
      
      final canUnlock = !usados.contains(languageName.trim().toLowerCase());
      debugPrint(canUnlock 
        ? '✅ $languageName NO ha sido usado para desbloquear'
        : '🚫 $languageName YA fue usado para desbloquear');
      
      return canUnlock;
    } catch (e) {
      debugPrint('❌ Error verificando si puede desbloquear: $e');
      return true; // Por defecto permitir
    }
  }

  /// Agrega un lenguaje al array lenguajes_completados del usuario
  Future<void> _addToCompletedLanguages(String userId, String languageName) async {
    try {
      debugPrint('📝 Agregando $languageName a lenguajes completados...');
      
      // Obtener array actual
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_completados')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ Usuario no encontrado');
        return;
      }

      final currentList = userResponse['lenguajes_completados'] as List?;
      final completados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      
      // Agregar el nuevo lenguaje (normalizado)
      completados.add(languageName.trim().toLowerCase());
      
      // Actualizar en BD
      await _supabase
          .from('usuarios')
          .update({'lenguajes_completados': completados.toList()})
          .eq('id', userId);

      debugPrint('✅ $languageName agregado a lenguajes_completados');
    } catch (e) {
      debugPrint('❌ Error agregando lenguaje completado: $e');
    }
  }

  /// Agrega un lenguaje al array lenguajes_seleccionados del usuario
  Future<void> _addToSelectedLanguages(String userId, String languageName) async {
    try {
      debugPrint('📝 Agregando $languageName a lenguajes seleccionados...');
      
      // Obtener array actual
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_seleccionados')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ Usuario no encontrado');
        return;
      }

      final currentList = userResponse['lenguajes_seleccionados'] as List?;
      final seleccionados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      
      // Agregar el nuevo lenguaje (normalizado)
      seleccionados.add(languageName.trim().toLowerCase());
      
      // Actualizar en BD
      await _supabase
          .from('usuarios')
          .update({'lenguajes_seleccionados': seleccionados.toList()})
          .eq('id', userId);

      debugPrint('✅ $languageName agregado a lenguajes_seleccionados');
    } catch (e) {
      debugPrint('❌ Error agregando lenguaje seleccionado: $e');
    }
  }

  /// Obtiene la lista de lenguajes desbloqueados para el usuario
  /// SÚPER OPTIMIZADO: Usa RPC function (1 sola query)
  Future<List<String>> _getUnlockedLanguages(String userId) async {
    try {
      debugPrint('🔓 Obteniendo lenguajes desbloqueados (RPC)...');
      
      // 🚀 1 SOLA QUERY usando RPC function
      final response = await _supabase.rpc(
        'get_unlocked_languages',
        params: {'user_id': userId},
      ) as List;

      final unlocked = response
          .map((row) => (row['language_name'] as String).trim().toLowerCase())
          .toList();

      debugPrint('🎯 Lenguajes desbloqueados: ${unlocked.join(", ")}');
      
      return unlocked;
    } catch (e) {
      debugPrint('❌ Error getting unlocked languages: $e');
      return [];
    }
  }

  /// Actualiza el lenguaje favorito del usuario
  Future<void> updateFavoriteLanguage(
    String userId, 
    String languageName, 
    {String? previousLanguage} // 🆕 Lenguaje que completaste antes
  ) async {
    try {
      debugPrint('🔄 Actualizando lenguaje favorito a: $languageName');
      
      // Obtener el ID del lenguaje (normalizar nombre)
      final normalizedName = languageName.trim().toLowerCase();
      debugPrint('🔍 Buscando lenguaje: $normalizedName');
      
      final languageResponse = await _supabase
          .from('lenguaje')
          .select('id_lenguaje, nombre')
          .ilike('nombre', normalizedName)
          .maybeSingle(); // Usar maybeSingle en lugar de single

      if (languageResponse == null) {
        debugPrint('❌ No se encontró el lenguaje: $normalizedName');
        throw Exception('Lenguaje no encontrado: $languageName');
      }

      final languageId = languageResponse['id_lenguaje'] as int;
      debugPrint('✅ ID del lenguaje encontrado: $languageId');

      // Actualizar en la BD (sin esperar resultado)
      await _supabase
          .from('usuarios')
          .update({'lenguaje_favorito': languageId})
          .eq('id', userId);

      debugPrint('✅ Lenguaje actualizado correctamente en BD');

      // 🆕 Si viene de completar un lenguaje, marcarlo como "usado para desbloquear"
      if (previousLanguage != null && previousLanguage.isNotEmpty) {
        await _markLanguageAsUsedForUnlock(userId, previousLanguage.trim().toLowerCase());
      }

      // 🆕 Agregar a lenguajes_seleccionados (para que quede permanentemente desbloqueado)
      await _addToSelectedLanguages(userId, normalizedName);

      // Actualizar el estado
      state = state.copyWith(currentLanguage: languageName.trim());
      debugPrint('✅ Estado local actualizado');
    } catch (e) {
      debugPrint('❌ Error updating favorite language: $e');
      rethrow;
    }
  }

  /// Marca un lenguaje como "usado para desbloquear otro"
  Future<void> _markLanguageAsUsedForUnlock(String userId, String languageName) async {
    try {
      debugPrint('📝 Marcando $languageName como usado para desbloquear...');
      
      // Obtener array actual
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_usados_desbloqueo')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) {
        debugPrint('❌ Usuario no encontrado');
        return;
      }

      final currentList = userResponse['lenguajes_usados_desbloqueo'] as List?;
      final usados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      
      // Agregar el lenguaje (normalizado)
      usados.add(languageName.trim().toLowerCase());
      
      // Actualizar en BD
      await _supabase
          .from('usuarios')
          .update({'lenguajes_usados_desbloqueo': usados.toList()})
          .eq('id', userId);

      debugPrint('✅ $languageName marcado como usado para desbloquear');
    } catch (e) {
      debugPrint('❌ Error marcando lenguaje como usado: $e');
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