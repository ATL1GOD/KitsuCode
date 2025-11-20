// lib/features/challenge/provider/language_completion_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final currentLanguageName = (langData?['nombre'] as String?)?.trim() ?? '';

      if (currentLanguageName.isEmpty) return;

      final normalizedCurrentLang = currentLanguageName.toLowerCase();

      // 3. Procesar Arrays
      final completadosList = List<String>.from(
        (userResponse['lenguajes_completados'] as List? ?? []).map((e) => e.toString().trim().toLowerCase())
      );

      final usadosList = List<String>.from(
        (userResponse['lenguajes_usados_desbloqueo'] as List? ?? []).map((e) => e.toString().trim().toLowerCase())
      );

      // 4. Lógica optimizada
      final isCompleted = completadosList.contains(normalizedCurrentLang);
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
      // rethrow; // Silencioso
    }
  }

  /// Verifica si un lenguaje puede desbloquear otro lenguaje
  Future<bool> _canLanguageUnlockAnother(String userId, String languageName) async {
    try {
      final userResponse = await _supabase
          .from('usuarios')
          .select('lenguajes_usados_desbloqueo')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse == null) return false;

      final usadosList = userResponse['lenguajes_usados_desbloqueo'] as List?;
      final usados = usadosList?.map((e) => e.toString().trim().toLowerCase()).toList() ?? [];
      
      return !usados.contains(languageName.trim().toLowerCase());
    } catch (e) {
      return true;
    }
  }

  Future<void> _addToCompletedLanguages(String userId, String languageName) async {
    try {
      final userResponse = await _supabase.from('usuarios').select('lenguajes_completados').eq('id', userId).maybeSingle();
      if (userResponse == null) return;
      final currentList = userResponse['lenguajes_completados'] as List?;
      final completados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      completados.add(languageName.trim().toLowerCase());
      await _supabase.from('usuarios').update({'lenguajes_completados': completados.toList()}).eq('id', userId);
    } catch (e) {}
  }

  Future<void> _removeFromCompletedLanguages(String userId, String languageName) async {
    try {
      final userResponse = await _supabase.from('usuarios').select('lenguajes_completados').eq('id', userId).maybeSingle();
      if (userResponse == null) return;
      final currentList = userResponse['lenguajes_completados'] as List?;
      final completados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      completados.remove(languageName.trim().toLowerCase());
      await _supabase.from('usuarios').update({'lenguajes_completados': completados.toList()}).eq('id', userId);
    } catch (e) {}
  }


  Future<void> _addToSelectedLanguages(String userId, String languageName) async {
    try {
      final userResponse = await _supabase.from('usuarios').select('lenguajes_seleccionados').eq('id', userId).maybeSingle();
      if (userResponse == null) return;
      final currentList = userResponse['lenguajes_seleccionados'] as List?;
      final seleccionados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      seleccionados.add(languageName.trim().toLowerCase());
      await _supabase.from('usuarios').update({'lenguajes_seleccionados': seleccionados.toList()}).eq('id', userId);
    } catch (e) {}
  }

  Future<List<String>> _getUnlockedLanguages(String userId) async {
    try {
      final response = await _supabase.rpc('get_unlocked_languages', params: {'user_id': userId}) as List;
      return response.map((row) => (row['language_name'] as String).trim().toLowerCase()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Actualiza el lenguaje favorito del usuario
  Future<void> updateFavoriteLanguage(
    String userId, 
    String languageName, 
    {String? previousLanguage} // ✅ Parámetro restaurado
  ) async {
    try {
      final normalizedName = languageName.trim().toLowerCase();
      
      final languageResponse = await _supabase
          .from('lenguaje')
          .select('id_lenguaje, nombre')
          .ilike('nombre', normalizedName)
          .maybeSingle();

      if (languageResponse == null) throw Exception('Lenguaje no encontrado: $languageName');
      final languageId = languageResponse['id_lenguaje'] as int;

      await _supabase.from('usuarios').update({'lenguaje_favorito': languageId}).eq('id', userId);

      if (previousLanguage != null && previousLanguage.isNotEmpty) {
        await _markLanguageAsUsedForUnlock(userId, previousLanguage.trim().toLowerCase());
      }

      await _addToSelectedLanguages(userId, normalizedName);
      state = state.copyWith(currentLanguage: languageName.trim());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _markLanguageAsUsedForUnlock(String userId, String languageName) async {
    try {
      final userResponse = await _supabase.from('usuarios').select('lenguajes_usados_desbloqueo').eq('id', userId).maybeSingle();
      if (userResponse == null) return;
      final currentList = userResponse['lenguajes_usados_desbloqueo'] as List?;
      final usados = currentList?.map((e) => e.toString()).toSet() ?? <String>{};
      usados.add(languageName.trim().toLowerCase());
      await _supabase.from('usuarios').update({'lenguajes_usados_desbloqueo': usados.toList()}).eq('id', userId);
    } catch (e) {}
  }

  void resetCompletionState() {
    state = state.copyWith(hasCompletedLanguage: false);
  }
}

final languageCompletionProvider =
    StateNotifierProvider<LanguageCompletionNotifier, LanguageCompletionState>(
  (ref) => LanguageCompletionNotifier(Supabase.instance.client),
);