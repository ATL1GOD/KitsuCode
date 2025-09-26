// lib/features/profile/provider/profile_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';

// Este provider manejará el estado de "cargando" mientras se guarda
final profileControllerProvider = StateNotifierProvider<ProfileController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileController(
    profileRepository: profileRepository,
    ref: ref,
  );
});

class ProfileController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileController({required ProfileRepository profileRepository, required Ref ref})
      : _profileRepository = profileRepository,
        _ref = ref,
        super(false); // false = no está cargando/guardando

  Future<bool> updateProfile({String? newName, String? newAvatar}) async {
    // Obtenemos el ID del usuario de forma segura
    final user = _ref.read(userProfileProvider).value;
    if (user == null) return false;

    state = true; // Empezamos a cargar (el botón mostrará un CircularProgressIndicator)
    try {
      await _profileRepository.updateUserProfile(
        userId: user.userId,
        newName: newName,
        newAvatar: newAvatar,
      );
      
      // FORZAMOS LA ACTUALIZACIÓN del perfil para que la pantalla principal muestre los nuevos datos
      _ref.refresh(userProfileProvider);

      state = false; // Terminamos de cargar
      return true; // Éxito
    } catch (e) {
      state = false; // Terminamos de cargar incluso si hay error
      return false; // Fracaso
    }
  }
}