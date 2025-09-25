// lib/features/profile/repository/mock_profile_repository.dart

import 'package:kitsucode/features/profile/model/user_profile_model.dart';

class MockProfileRepository {
  // El método para obtener el perfil se mantiene igual.
  Future<UserProfileModel> fetchUserProfile() async {
    await Future.delayed(const Duration(seconds: 1));
    return UserProfileModel(
      userId: '12345',
      nombreUsuario: 'atl1god',
      nombrePerfil: 'Atl Yosafat',
      avatarUrl: 'assets/images/login_zorro.png',
      siguiendoCount: 23,
      seguidoresCount: 50,
    );
  }

  // NUEVO: Método para actualizar el perfil
  // Recibe el perfil actual y los nuevos valores a cambiar.
  Future<UserProfileModel> updateUserProfile(
    UserProfileModel currentUser, {
    String? newUsername,
    String? newAvatarUrl,
  }) async {
    print("Simulando actualización en la base de datos...");
    // Simulamos una llamada a la red
    await Future.delayed(const Duration(milliseconds: 800));

    // Usamos el método copyWith que creamos para generar el perfil actualizado.
    final updatedProfile = currentUser.copyWith(
      nombreUsuario: newUsername,
      avatarUrl: newAvatarUrl,
    );

    print("¡Perfil simulado como actualizado!");
    // Devolvemos el perfil con los datos ya "guardados".
    return updatedProfile;
  }
}