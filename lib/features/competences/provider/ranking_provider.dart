// lib/features/competences/provider/ranking_provider.dart 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/repository/competence_repository.dart';

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