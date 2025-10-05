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
// Usaremos siempre este provider para obtener perfiles, pasándole el ID que necesitemos.
// Ya no necesitamos un 'userProfileProvider' separado.
final userProfileByIdProvider = FutureProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserProfileById(userId);
});


// Los providers de estadísticas y logros se quedan igual
final userStatsProvider = FutureProvider<UserStatsModel>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserStats();
});

final userAchievementsProvider = FutureProvider<List<UserAchievementModel>>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievements();
});
 

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/profile/model/user_profile_model.dart';
// // Importamos nuestro nuevo repositorio falso
// import 'package:kitsucode/features/profile/repository/mock_profile_repository.dart';

// // Provider para el Repositorio de Perfil (Falso)
// final profileRepositoryProvider = Provider((ref) {
//   // En lugar de conectar a Supabase, creamos una instancia del repositorio falso.
//   return MockProfileRepository();
// });

// // FutureProvider para los datos del perfil de usuario
// final userProfileProvider = FutureProvider<UserProfileModel>((ref) async {
//   final profileRepository = ref.watch(profileRepositoryProvider);
//   return profileRepository.fetchUserProfile();
// });