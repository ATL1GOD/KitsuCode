import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/home/repository/home_repository.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
// --- ¡CAMBIO 1: AÑADIR IMPORTACIÓN DE SUPABASE! ---
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ¡CAMBIO 2: AÑADIR ESTE PROVIDER DE REALTIME! ---
/// Este provider escucha en tiempo real las inserciones en la tabla `progreso_usuario`.
/// NO es autoDispose, para que siga vivo mientras el usuario está en un reto.
final progressRealtimeProvider = Provider<RealtimeChannel?>((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;

  // --- ¡¡AQUÍ ESTÁ LA CORRECCIÓN!! ---
  // Debe ser 'return null;' para que coincida con el tipo RealtimeChannel?
  if (currentUserId == null) return null; 
  // --- FIN DE LA CORRECCIÓN ---

  // El nombre del canal 'home_v2' es solo un ejemplo, puede ser lo que quieras
  final channel = supabase.channel('public:progreso_usuario:home_v2');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert, // Escuchamos solo inserciones
    schema: 'public',
    table: 'progreso_usuario', // <-- ¡La tabla clave que nos diste!
    // Filtramos para que solo nos notifique de NUESTRO propio progreso
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: currentUserId,
    ),
    callback: (payload) {
      debugPrint("--- Realtime: ¡NUEVO PROGRESO DE NIVEL DETECTADO! ---");
      
      // ¡Esta es la nueva lógica!
      // En lugar de invalidar, llamamos al nuevo método en el notifier.
      ref.read(homeViewModelProvider.notifier).triggerMapUpdate();
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return channel;
});
// --- FIN DEL CAMBIO 2 ---


// 1. El Provider (ViewModel)
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<SectionData>>(HomeViewModel.new);

// 2. El Notifier (Clase del ViewModel)
class HomeViewModel extends AsyncNotifier<List<SectionData>> {
  
  @override
  Future<List<SectionData>> build() async {
    // --- ¡CAMBIO 3: AÑADIR ESTA LÍNEA! ---
    // "Escuchamos" al provider para activarlo y mantenerlo vivo.
    // Esto asegura que el listener de Supabase se suscriba.
    ref.watch(progressRealtimeProvider);
    // --- FIN DEL CAMBIO 3 ---

    // --- ¡DEBUG! ---
    debugPrint("--- HomeViewModel: build() SE EJECUTÓ (Carga inicial) ---");

    // 1. Observamos SOLO el languageId
    final languageId = ref.watch(currentLanguageIdProvider);

    // --- ¡DEBUG! ---
    debugPrint("HomeViewModel: 'languageId' observado -> $languageId");

    // 2. Si el ID es 0, retornamos una lista vacía
    if (languageId == 0) {
      
      // --- ¡DEBUG! ---
      debugPrint("HomeViewModel: languageId es 0. Retornando mapa vacío [].");
      
      return [];
    }

    // --- ¡DEBUG! ---
    debugPrint("HomeViewModel: Llamando a _fetchSections con ID: $languageId");

    // 3. Cargamos las secciones.
    return _fetchSections(languageId);
  }

  // --- ¡CAMBIO 4: AÑADIR ESTE NUEVO MÉTODO! ---
  /// Vuelve a cargar los datos del mapa y actualiza el estado
  /// directamente a AsyncData, evitando el "pantallazo negro" de carga.
  Future<void> triggerMapUpdate() async {
    debugPrint("--- Realtime: triggerMapUpdate() llamado ---");
    final languageId = ref.read(currentLanguageIdProvider);
    if (languageId == 0) return;

    try {
      // 1. Volvemos a ejecutar la lógica de carga
      final newSections = await _fetchSections(languageId);
      
      // 2. ¡ESTA ES LA CLAVE!
      // Actualizamos el estado directamente a AsyncData.
      // La UI recibirá la nueva lista y se reconstruirá
      // sin mostrar un estado de 'loading'.
      state = AsyncData(newSections);
      
      debugPrint("--- Realtime: ¡Mapa actualizado en vivo! ---");
      
    } catch (e, s) {
      // Si algo falla, sí pasamos al estado de error
      state = AsyncError(e, s);
      debugPrint("--- Realtime: Error al actualizar mapa: $e ---");
    }
  }
  // --- FIN DEL CAMBIO 4 ---


  // (El resto de tu clase no cambia)

  Future<List<SectionData>> _fetchSections(int languageId) async {
    final repository = ref.read(sectionRepositoryProvider); // .read es mejor aquí

    // 1. Obtenemos los datos (ambas listas)
    final HomeMapData homeData = await repository.getHomeMapData(languageId);

    final List<SectionData> sections = homeData.sections;
    final Set<int> completedIds = homeData.completedLevelIds;

    // 2. Aplicamos el PROGRESO (isCompleted) manualmente
    final List<SectionData> sectionsWithProgress = sections.map((section) {
      final List<LevelData> updatedLevels = section.levels.map((level) {
        final bool isCompleted = completedIds.contains(level.idNivel);

        return level.copyWith(
          isCompleted: isCompleted, // ¡Aplicamos el progreso!
        );
      }).toList();

      return section.copyWith(levels: updatedLevels);
    }).toList();

    debugPrint("--- DATOS ANTES DE LÓGICA (PROGRESO APLICADO) ---");
    for (var sec in sectionsWithProgress) {
      for (var lvl in sec.levels) {
        debugPrint(
          'Seccion ${sec.etapa}, Nivel ${lvl.nivel} (ID: ${lvl.idNivel}), isCompleted: ${lvl.isCompleted}',
        );
      }
    }

    // 3. ¡Aplicamos la lógica de BLOQUEO (isLocked)!
    final List<SectionData> finalSections =
        SectionData.applySequentialSectionLock(sectionsWithProgress);

    debugPrint("--- DATOS DESPUÉS DE LÓGICA (BLOQUEO APLICADO) ---");
    for (var sec in finalSections) {
      for (var lvl in sec.levels) {
        debugPrint(
          'Seccion ${sec.etapa}, Nivel ${lvl.nivel}, isLocked: ${lvl.isLocked}',
        );
      }
    }

    // 4. Devolvemos la lista final a la UI
    return finalSections;
  }

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