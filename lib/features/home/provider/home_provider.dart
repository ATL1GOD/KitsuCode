import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart'; // ¡Importante!
import 'package:kitsucode/features/home/repository/home_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- SOLUCIÓN A: (Evitar Race Condition) ---
// Escucha el Realtime y pasa el ID del nivel nuevo
final progressRealtimeProvider = Provider<RealtimeChannel?>((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;

  if (currentUserId == null) return null;

  final channel = supabase.channel('public:progreso_usuario:home_v3');
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
          // Llama al método que actualiza el estado localmente
          ref.read(homeViewModelProvider.notifier).unlockLevelLocally(newLevelId);
        }
      } catch (e) {
        ref.read(homeViewModelProvider.notifier).triggerMapUpdate();
      }
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return channel;
});
// --- FIN SOLUCIÓN A ---


final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  
  @override
  Future<List<SectionData>> build() async {
    ref.watch(progressRealtimeProvider); // Activa el listener

    final languageId = ref.watch(currentLanguageIdProvider);
    
    if (languageId == 0) {
      return [];
    }
    
    return _fetchSections(languageId);
  }

  /// SOLUCIÓN A: Actualiza el estado localmente sin re-consultar
  void unlockLevelLocally(int newLevelId) {
    final currentState = state.value;
    if (currentState == null) {
      triggerMapUpdate(); // No hay datos, mejor recargar
      return;
    }

    // 1. Marcar el nuevo nivel como 'completado' en el estado actual
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

    // 2. Volver a correr la lógica de BLOQUEO (de home_model.dart)
    final List<SectionData> finalSections =
        SectionData.applySequentialSectionLock(sectionsWithNewProgress);

    // 3. Actualizar la UI
    state = AsyncData(finalSections);
  }


  /// Fallback por si `unlockLevelLocally` falla
  Future<void> triggerMapUpdate() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Dar tiempo a la BD
    
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
      debugPrint("--- 🚀 _fetchSections INICIADO para lenguaje: $languageId ---");
      final repository = ref.read(sectionRepositoryProvider);
      final HomeMapData homeData = await repository.getHomeMapData(languageId);
      final List<SectionData> sections = homeData.sections;
    
    // --- ¡¡INICIO DE LA CORRECCIÓN!! ---
    // ¡Usamos los ID de progreso que SÍ vienen del repositorio!
    final Set<int> completedIds = homeData.completedLevelIds; 
    // --- ¡¡FIN DE LA CORRECCIÓN!! ---


    // --- SOLUCIÓN B: (Ordenar Niveles) ---
    // 1. Ordenar manualmente los niveles DENTRO de cada sección
    final List<SectionData> sortedSections = sections.map((section) {
      final sortedLevels = List<LevelData>.from(section.levels);
      
      // ¡Ordena por el campo 'nivel' (que es 'niveles.orden')!
      sortedLevels.sort((a, b) => a.nivel.compareTo(b.nivel)); 
      
      return section.copyWith(levels: sortedLevels);
    }).toList();
    // --- FIN SOLUCIÓN B ---

    // 2. Aplicar el progreso (isCompleted) a la lista YA ORDENADA
    final List<SectionData> sectionsWithProgress = sortedSections.map((section) { 
      final List<LevelData> updatedLevels = section.levels.map((level) {
        // ¡Ahora 'completedIds' tiene los datos correctos!
        final bool isCompleted = completedIds.contains(level.idNivel);
        
        return level.copyWith(
          isCompleted: isCompleted,
        );
      }).toList();
      return section.copyWith(levels: updatedLevels);
    }).toList();

    // 3. Aplicar bloqueo (usando la función de home_model.dart)
    final List<SectionData> finalSections =
        SectionData.applySequentialSectionLock(sectionsWithProgress);
    
    return finalSections;
    } catch (e, stack) {
      debugPrint("--- ❌ ERROR EN _fetchSections: $e ---");
      debugPrint("--- STACK: $stack ---");
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