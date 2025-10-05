// lib/features/profile/provider/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
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
// Usaremos siempre este provider para obtener cualquier perfil, pasándole el ID que necesitemos.
final userProfileByIdProvider = FutureProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserProfileById(userId);
});


// Los providers de estadísticas y logros se quedan igual y no necesitan cambios.
final userStatsProvider = FutureProvider<UserStatsModel>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserStats();
});

final userAchievementsProvider = FutureProvider<List<UserAchievementModel>>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievements();
});