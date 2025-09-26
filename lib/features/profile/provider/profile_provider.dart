import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Este provider crea y provee la instancia del ProfileRepository real
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
});

// Este provider llama a fetchUserProfile y le da los datos a la pantalla
final userProfileProvider = FutureProvider<UserProfileModel>((ref) async {
  // Pide el repositorio real
  final profileRepository = ref.watch(profileRepositoryProvider);
  // Llama a la función para obtener los datos de Supabase
  return profileRepository.fetchUserProfile();
});

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