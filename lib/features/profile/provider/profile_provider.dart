// lib/features/profile/provider/profile_provider.dart

import 'package:flutter/foundation.dart'; // <-- ¡IMPORTADO PARA debugPrint!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para el repositorio de perfil
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
});

// Provider para obtener el perfil de un usuario por su ID
final userProfileByIdProvider = StreamProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.watchUserProfileById(userId);
});

// Provider para las estadísticas
final userStatsProvider = FutureProvider.autoDispose.family<UserStatsModel, String>((ref, userId) {
    final repository = ref.watch(profileRepositoryProvider);
    // ¡ESTA LÍNEA ESTÁ INCORRECTA!
    return repository.fetchUserStats(); 
});

// Provider para los logros
final userAchievementsProvider = FutureProvider.family<List<UserAchievementModel>, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievementsById(userId);
});

final userStatsByIdProvider = FutureProvider.autoDispose.family<UserStatsModel, String>((ref, userId) {
  final repository = ref.watch(profileRepositoryProvider);
  // ¡Esta es la llamada correcta!
  return repository.fetchUserStatsById(userId);
});

// Provider de Realtime para seguimiento (sin cambios)
final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'seguimiento_usuario',
    callback: (payload) {
      // ignore: avoid_print
      debugPrint('Cambio detectado en seguimiento_usuario: $payload');
      final eventType = payload.eventType;
      final record = eventType == PostgresChangeEvent.insert ? payload.newRecord : payload.oldRecord;

      if (record.isNotEmpty) {
        final followerId = record['id_usuario'];
        final followedId = record['id_usuario_seguido'];

        ref.invalidate(userProfileByIdProvider(followerId));
        ref.invalidate(userProfileByIdProvider(followedId));
      }
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
  return channel;
});

// --- ¡NUEVO Provider de Realtime para el Perfil (CORREGIDO)! ---
final profileRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // 1. Canal para cambios en 'usuarios' (nombre_perfil, avatar_url)
  final userChannel = supabase.channel('public:usuarios:profile');
  userChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'usuarios',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: userId,
    ),
    callback: (payload) {
      debugPrint("CAMBIO EN USUARIOS (PERFIL) DETECTADO -> Invalidando providers de perfil");
      // --- ¡ARREGLADO! ---
      // Invalidamos el provider de datos, no el controlador
      ref.invalidate(userProfileByIdProvider(userId));
    },
  ).subscribe();

  // 2. Canal para cambios en 'estadistica_usuario' (retos_completados, etc.)
  final statsChannel = supabase.channel('public:estadistica_usuario:profile');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'estadistica_usuario',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      debugPrint("CAMBIO EN ESTADISTICAS (STATS) DETECTADO -> Invalidando providers de perfil");
      // --- ¡ARREGLADO! ---
      // Invalidamos el provider de datos, no el controlador
      ref.invalidate(userStatsByIdProvider(userId));
    },
  ).subscribe();

  // Limpiar canales
  ref.onDispose(() {
    supabase.removeChannel(userChannel);
    supabase.removeChannel(statsChannel);
  });
});