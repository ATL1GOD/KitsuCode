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
      
      // FORZAR EL REFRESH y capturar el nuevo valor
      // Esta línea hace que la próxima vez que se lea userProfileProvider, 
      // se haga una nueva llamada a Supabase.
      // Usamos .future para esperar a que termine la nueva llamada a Supabase y obtener el resultado.
      final updatedProfile = await _ref.refresh(userProfileProvider.future); 
      
      state = false; 
      // Devolvemos el perfil recién cargado de Supabase, que contiene los contadores actualizados.
      return updatedProfile; 
      
    } catch (e) {
      // Manejar errores de Supabase, por ejemplo, límites excedidos por el trigger
      // ... 
      state = false; 
      return null; 
    }
  }
}
