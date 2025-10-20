// lib/features/competences/provider/ranking_provider.dart 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/repository/competence_repository.dart';
// ¡Importamos la librería de Supabase para Realtime!
import 'package:supabase_flutter/supabase_flutter.dart';

// Proveedores para los filtros (valores iniciales)
final selectedLanguageProvider = StateProvider.autoDispose<int>((ref) => 1); 
final selectedDifficultyProvider = StateProvider.autoDispose<int>((ref) => 1); 

// Proveedores para la UI (Añadimos la ruta del logo)
final allLanguagesProvider = Provider.autoDispose<Map<int, Map<String, String>>>((ref) => {
      1: {'name': 'Python', 'logo': 'images/logo_python.png'}, // Asume esta ruta
      2: {'name': 'C', 'logo': 'images/logo_c.png'}, 
      3: {'name': 'Java', 'logo': 'images/logo_java.png'},
});

// Cambiamos allDifficultiesProvider 
final allDifficultiesProvider = Provider.autoDispose<Map<int, String>>((ref) => {
      1: 'Histórico',
      2: 'Últimos 30 Días',
      3: 'Última Semana',
});

// CRÍTICO: Cambia la selección de dificultad a selección de tiempo
final selectedTimeFilterProvider = StateProvider.autoDispose<int>((ref) => 1); 

// Y en globalRankingProvider: usa selectedTimeFilterProvider
final globalRankingProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  final repository = ref.watch(competenceRepositoryProvider);
  final langId = ref.watch(selectedLanguageProvider); 
  final diffId = ref.watch(selectedTimeFilterProvider); // Pasamos el filtro de tiempo aquí
  
  return repository.fetchGlobalRanking(langId, diffId);
});


// --- CÓDIGO NUEVO PARA ACTUALIZAR EL RANKING EN TIEMPO REAL ---
final rankingRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:estadistica_usuario');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all, // Escucha cualquier cambio
    schema: 'public',
    table: 'estadistica_usuario',
    callback: (payload) {
      // Cuando las estadísticas de cualquier usuario cambien...
      // ignore: avoid_print
      print('Cambio de estadísticas detectado, actualizando ranking...');
      // ¡Invalidamos el provider del ranking para que se recargue!
      ref.invalidate(globalRankingProvider);
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
});