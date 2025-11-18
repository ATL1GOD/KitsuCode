// [COMIENZO DEL ARCHIVO ranking_provider.dart]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/repository/competence_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ¡IMPORTACIÓN NECESARIA! ---
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

// 🔥 1. IMPORTAR EL CONNECTIVITY PROVIDER
import 'package:kitsucode/core/providers/connectivity_provider.dart';


// --- Filtros (Sin cambios) ---
final selectedLanguageProvider = StateProvider.autoDispose<int>((ref) {
  final appBarState = ref.watch(appBarProvider);
  if (appBarState.languageId == 0) {
    return 1;
  }
  return appBarState.languageId;
});
final allLanguagesProvider =
    Provider.autoDispose<Map<int, Map<String, String>>>((ref) => {
          1: {'name': 'C', 'logo': 'images/home/logo_c.webp'},
          2: {'name': 'Java', 'logo': 'images/home/logo_java.webp'},
          3: {'name': 'Python', 'logo': 'images/home/logo_python.webp'},
        });
final allTimeFiltersProvider = Provider.autoDispose<Map<int, String>>((ref) => {
      1: 'Histórico',
      2: 'Últimos 30 Días',
      3: 'Última Semana',
    });
final selectedTimeFilterProvider = StateProvider.autoDispose<int>((ref) => 1);


// --- Provider de Ranking Global ---
// 🔥 MODIFICADO: Ahora reacciona a la conexión
final globalRankingProvider =
    FutureProvider.autoDispose<List<RankingModel>>((ref) async {

  // 🔥 2. AÑADIR ESTE BLOQUE
  // Esperar a que la conexión esté confirmada
  final connectivityStatus = await ref.watch(connectivityProvider.future);

  // Si no estamos 'online', lanza un error
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }

  // --- LÓGICA ORIGINAL ---
  final repository = ref.watch(competenceRepositoryProvider);
  final langId = ref.watch(selectedLanguageProvider);
  final diffId = ref.watch(selectedTimeFilterProvider);

  return repository.fetchGlobalRanking(langId, diffId);
});

// --- Provider de Realtime (Sin cambios) ---
final realtimeUpdateProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser; 

  // --- Listener 1: Cambios en 'intento_reto' (actualiza el Ranking) ---
  final rankingChannel = supabase.channel('public:intento_reto');
  rankingChannel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'intento_reto',
    callback: (payload) {
      print('Cambio en "intento_reto" detectado, actualizando ranking...');
      ref.invalidate(globalRankingProvider);
    },
  ).subscribe();

  // --- Listener 2: Cambios en 'estadistica_usuario' (actualiza el AppBar) ---
  final statsChannel = supabase.channel('public:estadistica_usuario');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'estadistica_usuario',
    callback: (payload) {
      if (user != null && payload.newRecord['id_usuario'] == user.id) {
        print(
            'Cambio en "estadistica_usuario" detectado, actualizando AppBar...');
        ref.read(appBarProvider.notifier).fetchStats();
      }
    },
  ).subscribe();

  // --- ¡NUEVO Listener 3! ---
  if (user != null) {
    final userChannel = supabase.channel('public:usuarios:ranking');
    userChannel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'usuarios',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: user.id,
      ),
      callback: (payload) {
        print('Cambio en "usuarios" detectado, actualizando AppBar...');
        ref.read(appBarProvider.notifier).fetchStats();
      },
    ).subscribe();

    ref.onDispose(() {
      supabase.removeChannel(rankingChannel);
      supabase.removeChannel(statsChannel);
      supabase.removeChannel(userChannel); 
    });
  } else {
    ref.onDispose(() {
      supabase.removeChannel(rankingChannel);
      supabase.removeChannel(statsChannel);
    });
  }
});
// [FIN DEL ARCHIVO ranking_provider.dart]