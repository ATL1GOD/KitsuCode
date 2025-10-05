// lib/features/profile/provider/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart'; // No se usa directamente pero es bueno mantenerlo por si acaso
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para el repositorio, no cambia.
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
});

// --- ÚNICA FUENTE DE VERDAD PARA PERFILES DE USUARIO ---
final userProfileByIdProvider = FutureProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserProfileById(userId);
});

// Providers de estadísticas y logros (sin cambios).
final userStatsProvider = FutureProvider<UserStatsModel>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserStats();
});

final userAchievementsProvider = FutureProvider<List<UserAchievementModel>>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievements();
});

// --- CÓDIGO FINAL USANDO TU SOLUCIÓN CORRECTA ---
final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');

  // Usamos el método onPostgresChanges, que es el correcto y más moderno.
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all, // Escucha INSERT, UPDATE y DELETE
    schema: 'public',
    table: 'seguimiento_usuario',
    callback: (payload) {
      // ignore: avoid_print
      print('Cambio detectado en seguimiento_usuario: $payload');

      final eventType = payload.eventType;
      // Usamos los campos correctos del payload: newRecord y oldRecord
      final record = eventType == PostgresChangeEvent.insert ? payload.newRecord : payload.oldRecord;

      if (record != null && record.isNotEmpty) {
        final followerId = record['id_usuario'];
        final followedId = record['id_usuario_seguido'];

        // Invalidamos los perfiles para forzar la actualización en la UI
        ref.invalidate(userProfileByIdProvider(followerId));
        ref.invalidate(userProfileByIdProvider(followedId));
      }
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
});