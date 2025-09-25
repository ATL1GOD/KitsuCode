// // lib/features/profile/provider/profile_provider.dart

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kitsucode/features/profile/model/user_profile_model.dart';
// import 'package:kitsucode/features/profile/repository/profile_repository.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // <-- 1. Importante

// // Provider para el Repositorio
// final profileRepositoryProvider = Provider((ref) {
//   // 2. Obtenemos la instancia del cliente de Supabase, ¡esta es la forma correcta!
//   final supabaseClient = Supabase.instance.client;
//   return ProfileRepository(supabaseClient);
// });

// // FutureProvider para los datos del perfil
// final userProfileProvider = FutureProvider<UserProfileModel>((ref) async {
//   // 3. Le pedimos al provider del repositorio que haga su trabajo
//   final profileRepository = ref.watch(profileRepositoryProvider);
//   return profileRepository.fetchUserProfile();
// });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
// Importamos nuestro nuevo repositorio falso
import 'package:kitsucode/features/profile/repository/mock_profile_repository.dart';

// Provider para el Repositorio (AHORA USA EL FALSO)
final profileRepositoryProvider = Provider((ref) {
  // En lugar de conectar a Supabase, creamos una instancia del repositorio falso.
  return MockProfileRepository();
});

// FutureProvider para los datos del perfil (Este no cambia)
final userProfileProvider = FutureProvider<UserProfileModel>((ref) async {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserProfile();
});