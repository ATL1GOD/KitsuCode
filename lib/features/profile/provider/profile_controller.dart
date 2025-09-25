// lib/features/profile/provider/profile_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';

final profileControllerProvider = StateNotifierProvider<ProfileController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileController(
    profileRepository: profileRepository,
    ref: ref,
  );
});

class ProfileController extends StateNotifier<bool> {
  final dynamic _profileRepository;
  final Ref _ref;

  ProfileController({required dynamic profileRepository, required Ref ref})
      : _profileRepository = profileRepository,
        _ref = ref,
        super(false);

  Future<bool> updateProfile({String? newName, String? newAvatar}) async {
    // Obtenemos los datos del usuario de forma segura
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile == null) return false; // Si no hay datos, no hacemos nada

    state = true; // Empezamos a cargar
    try {
      await _profileRepository.updateUserProfile(
        userId: userProfile.userId,
        newName: newName,
        newAvatar: newAvatar,
      );
      
      // Forzamos la actualización del perfil para que la pantalla principal muestre los nuevos datos
      _ref.refresh(userProfileProvider);

      state = false; // Terminamos de cargar
      return true; // Éxito
    } catch (e) {
      state = false; // Terminamos de cargar incluso si hay error
      return false; // Fracaso
    }
  }
}