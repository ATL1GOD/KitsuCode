import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/repository/competence_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ¡NUEVA IMPORTACIÓN! ---
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';


// (Tus providers de filtros: selectedLanguageProvider, allLanguagesProvider, etc. no cambian)
final selectedLanguageProvider = StateProvider.autoDispose<int>((ref) => 1); 
final selectedDifficultyProvider = StateProvider.autoDispose<int>((ref) => 1); 
final allLanguagesProvider = Provider.autoDispose<Map<int, Map<String, String>>>((ref) => {
      1: {'name': 'Python', 'logo': 'images/logo_python.png'}, 
      2: {'name': 'C', 'logo': 'images/logo_c.png'}, 
      3: {'name': 'Java', 'logo': 'images/logo_java.png'},
});
final allDifficultiesProvider = Provider.autoDispose<Map<int, String>>((ref) => {
      1: 'Histórico',
      2: 'Últimos 30 Días',
      3: 'Última Semana',
});
final selectedTimeFilterProvider = StateProvider.autoDispose<int>((ref) => 1); 

// (Tu globalRankingProvider no cambia)
final globalRankingProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  final repository = ref.watch(competenceRepositoryProvider);
  final langId = ref.watch(selectedLanguageProvider); 
  final diffId = ref.watch(selectedTimeFilterProvider); 
  
  return repository.fetchGlobalRanking(langId, diffId);
});


// --- ¡CAMBIO GRANDE AQUÍ! ---
// Este provider ahora maneja TODOS los listeners de Realtime
final realtimeUpdateProvider = Provider((ref) {
  final supabase = Supabase.instance.client;

  // --- Listener 1: Cambios en 'intento_reto' (actualiza el Ranking) ---
  final rankingChannel = supabase.channel('public:intento_reto');
  rankingChannel.onPostgresChanges(
    event: PostgresChangeEvent.all, // Escucha INSERT, UPDATE, DELETE
    schema: 'public',
    table: 'intento_reto', // <-- ¡TABLA CORRECTA!
    callback: (payload) {
      print('Cambio en "intento_reto" detectado, actualizando ranking...');
      // Invalida el ranking para que se recargue
      ref.invalidate(globalRankingProvider);
    },
  ).subscribe();

  // --- Listener 2: Cambios en 'estadistica_usuario' (actualiza el AppBar) ---
  final statsChannel = supabase.channel('public:estadistica_usuario');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update, // Solo nos importa cuando se actualiza
    schema: 'public',
    table: 'estadistica_usuario',
    callback: (payload) {
      // Verificamos si el cambio es del usuario actual
      final user = supabase.auth.currentUser;
      if (user != null && payload.newRecord['id_usuario'] == user.id) {
        print('Cambio en "estadistica_usuario" detectado, actualizando AppBar...');
        // Refresca el AppBar (para la racha, etc.)
        ref.read(appBarProvider.notifier).fetchStats();
      }
    },
  ).subscribe();


  ref.onDispose(() {
    supabase.removeChannel(rankingChannel);
    supabase.removeChannel(statsChannel);
  });
});