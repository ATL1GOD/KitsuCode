// lib/features/competences/provider/ranking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/repository/competence_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- ¡IMPORTACIÓN NECESARIA! ---
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';


// --- ¡CAMBIO 1! ---
// Hacemos que el filtro de lenguaje por defecto escuche al appBarProvider
final selectedLanguageProvider = StateProvider.autoDispose<int>((ref) {
  // Observamos (watch) el appBarProvider
  final appBarState = ref.watch(appBarProvider);

  // Si el appBarProvider aún está cargando (ID es 0), 
  // usamos 1 (Python) como fallback temporal.
  if (appBarState.languageId == 0) {
    return 1; 
  }
  
  // En cuanto el appBarProvider carga, este provider se
  // actualizará y usará el lenguaje favorito del usuario.
  return appBarState.languageId;
}); 

// (El resto de tus filtros no cambian)
final selectedDifficultyProvider = StateProvider.autoDispose<int>((ref) => 1); 
final allLanguagesProvider = Provider.autoDispose<Map<int, Map<String, String>>>((ref) => {
      // OJO: Asegúrate que estos IDs coincidan con tu DB
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

// (globalRankingProvider no cambia, ya funciona bien)
final globalRankingProvider = FutureProvider.autoDispose<List<RankingModel>>((ref) async {
  final repository = ref.watch(competenceRepositoryProvider);
  // 'watch'ea los filtros. Cuando cambien, este provider se recargará.
  final langId = ref.watch(selectedLanguageProvider); 
  final diffId = ref.watch(selectedTimeFilterProvider); 
  
  return repository.fetchGlobalRanking(langId, diffId);
});


// --- ¡CAMBIO 2! ---
// Añadimos el listener de la tabla 'usuarios' a tu provider de realtime
final realtimeUpdateProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser; // Obtener el usuario actual

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
        print('Cambio en "estadistica_usuario" detectado, actualizando AppBar...');
        ref.read(appBarProvider.notifier).fetchStats();
      }
    },
  ).subscribe();

  // --- ¡NUEVO Listener 3! ---
  // Cambios en 'usuarios' (actualiza el AppBar y el filtro por defecto)
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
        // Refrescar el AppBar (lo que CASCADeará el cambio 
        // al 'selectedLanguageProvider' gracias al 'watch' que pusimos)
        ref.read(appBarProvider.notifier).fetchStats();
      },
    ).subscribe();

    ref.onDispose(() {
      supabase.removeChannel(rankingChannel);
      supabase.removeChannel(statsChannel);
      supabase.removeChannel(userChannel); // Limpiamos el nuevo canal
    });

  } else {
    // Si no hay usuario, solo limpiamos los canales públicos
    ref.onDispose(() {
      supabase.removeChannel(rankingChannel);
      supabase.removeChannel(statsChannel);
    });
  }
});