// profile_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';

// Este provider manejará el estado de "cargando" mientras se guarda
final profileControllerProvider =
    StateNotifierProvider<ProfileController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileController(
    profileRepository: profileRepository,
    ref: ref,
  );
});

class ProfileController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileController({
    required ProfileRepository profileRepository,
    required Ref ref,
  })  : _profileRepository = profileRepository,
        _ref = ref,
        super(false); // false = no está cargando/guardando

  Future<UserProfileModel?> updateProfile({String? newName, String? newAvatar}) async {
    final user = _ref.read(userProfileProvider).value;
    if (user == null) return null;

    state = true; 
    try {
      await _profileRepository.updateUserProfile(
        userId: user.userId,
        newName: newName,
        newAvatar: newAvatar,
      );
      
      // 1. FORZAMOS LA INVALIDACIÓN para descartar el valor en caché ANTES de esperar.
      _ref.invalidate(userProfileProvider);
      
      // 2. Mantenemos el respiro de 500ms para que el trigger de Postgres termine.
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 3. LEEMOS el proveedor. La invalidación anterior asegura que se hace
      //    una nueva llamada a fetchUserProfile() para obtener los contadores frescos.
      final updatedProfile = await _ref.read(userProfileProvider.future); 
      
      state = false; 
      // Devolvemos el perfil recién cargado de Supabase.
      return updatedProfile; 
      
    } catch (e) {
      // Manejar errores de Supabase, por ejemplo, límites excedidos por el trigger
      // ... 
      state = false; 
      return null; 
    }
  }
}