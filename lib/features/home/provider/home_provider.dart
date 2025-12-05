import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart'; // ¡Importante!
import 'package:kitsucode/features/home/repository/home_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// provider de progreso en tiempo real (TU CÓDIGO - SIN CAMBIOS)
final progressRealtimeProvider = Provider<RealtimeChannel?>((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;

  if (currentUserId == null) return null;

  final channel = supabase.channel('public:progreso_usuario:home_v4'); 
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'progreso_usuario',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: currentUserId,
    ),
    callback: (payload) {
      try {
        final newRecord = payload.newRecord;
        if (newRecord.isEmpty) return;
        
        final newLevelId = newRecord['id_nivel'] as int?;
        
        if (newLevelId != null) {
          final notifier = ref.read(homeViewModelProvider.notifier);
          notifier.unlockLevelLocally(newLevelId);
        }
      } catch (e) {
        try {
          final notifier = ref.read(homeViewModelProvider.notifier);
          notifier.triggerMapUpdate();
        } catch (_) {
          // Si el provider no existe, ignoramos
        }
      }
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return channel;
});
// --- (Fin de provider) ---


/// Este provider guarda el ID del último nivel desbloqueado (SIN CAMBIOS)
final newlyUnlockedLevelProvider = StateProvider<int?>((ref) => null);
// --- FIN ---

// --- ¡¡INICIO DE LA MODIFICACIÓN!! ---
/// Provider que escucha cambios ESTRUCTURALES en el mapa (nuevos niveles/secciones).
/// Ahora con autoDispose para evitar memory leaks
final mapStructureRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;

  final channel = supabase.channel('public:map_structure_changes');

  void reloadMap(dynamic payload) {
    debugPrint("--- Realtime: ¡Cambio ESTRUCTURAL detectado en el mapa! Recargando... ---");
    // Invalidamos el provider principal del mapa.
    ref.invalidate(homeViewModelProvider);
  }

  // Escuchamos INSERT, UPDATE o DELETE en niveles Y secciones
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all, // Escucha INSERT, UPDATE, DELETE
        schema: 'public',
        table: 'niveles',
        callback: reloadMap,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all, // Escucha INSERT, UPDATE, DELETE
        schema: 'public',
        table: 'secciones',
        callback: reloadMap,
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  // ¡Devolvemos el canal para que el provider tenga un valor!
  return channel; 
});
// --- ¡¡FIN DE LA MODIFICACIÓN!! ---


final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  
  @override
  Future<List<SectionData>> build() async {
    // --- ¡MODIFICACIÓN! ---
    // ¡Quitamos el watch de aquí!
    // ref.watch(mapStructureRealtimeProvider); // <-- ¡LÍNEA ELIMINADA!
    // --- FIN DE LA MODIFICACIÓN ---

    // (Tu lógica original de build)
    final languageId = ref.watch(currentLanguageIdProvider);
    if (languageId == 0) {
      return [];
    }
    return _fetchSections(languageId);
  }

  // --- (El resto de tu clase HomeViewModel está perfecta, no necesita cambios) ---

  /// SOLUCIÓN A: Actualiza el estado localmente sin re-consultar
  void unlockLevelLocally(int newLevelId) {
    final currentState = state.value;
    if (currentState == null) {
      triggerMapUpdate(); 
      return;
    }

    final List<SectionData> sectionsWithNewProgress = currentState.map((section) {
      return section.copyWith(
        levels: section.levels.map((level) {
          if (level.idNivel == newLevelId) {
            return level.copyWith(isCompleted: true);
          }
          return level;
        }).toList(),
      );
    }).toList();

    final List<SectionData> finalSections =
        SectionData.applySequentialSectionLock(sectionsWithNewProgress);

    int? levelToAnimate;
    bool foundCompletedLevel = false;
    final allLevelsOrdered = finalSections.expand((section) => section.levels);

    for (final level in allLevelsOrdered) {
      if (foundCompletedLevel) {
        if (!level.isLocked) {
           levelToAnimate = level.idNivel;
        }
        break; 
      }
      if (level.idNivel == newLevelId) {
        foundCompletedLevel = true;
      }
    }

    if (levelToAnimate != null) {
      ref.read(newlyUnlockedLevelProvider.notifier).state = levelToAnimate;
    }

    state = AsyncData(finalSections);
  }
  
  /// Fallback por si `unlockLevelLocally` falla
  Future<void> triggerMapUpdate() async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    
    final languageId = ref.read(currentLanguageIdProvider);
    if (languageId == 0) return;
    try {
      final newSections = await _fetchSections(languageId);
      state = AsyncData(newSections);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  
  /// Esta función ahora contiene la SOLUCIÓN B y la C (Corrección)
  Future<List<SectionData>> _fetchSections(int languageId) async {
    try {
      final repository = ref.read(sectionRepositoryProvider);
      final HomeMapData homeData = await repository.getHomeMapData(languageId);
      final List<SectionData> sections = homeData.sections;
    
      final Set<int> completedIds = homeData.completedLevelIds; 

      final List<SectionData> sortedSections = sections.map((section) {
        final sortedLevels = List<LevelData>.from(section.levels);
        sortedLevels.sort((a, b) => a.nivel.compareTo(b.nivel)); 
        return section.copyWith(levels: sortedLevels);
      }).toList();

      final List<SectionData> sectionsWithProgress = sortedSections.map((section) { 
        final List<LevelData> updatedLevels = section.levels.map((level) {
          final bool isCompleted = completedIds.contains(level.idNivel);
          return level.copyWith(
            isCompleted: isCompleted,
          );
        }).toList();
        return section.copyWith(levels: updatedLevels);
      }).toList();

      final List<SectionData> finalSections =
          SectionData.applySequentialSectionLock(sectionsWithProgress);
          
      return finalSections;
    } catch (e) {
      rethrow;
    }
  }

  // refreshSections no cambia
  Future<void> refreshSections() async {
    state = const AsyncValue.loading();
    final languageId = ref.read(currentLanguageIdProvider);
    if (languageId == 0) {
      state = await AsyncValue.guard(() => Future.value([]));
      return;
    }
    state = await AsyncValue.guard(() => _fetchSections(languageId));
  }
}