// lib/features/profile/repository/mock_profile_repository.dart

import 'package:kitsucode/features/profile/model/user_profile_model.dart';

// Este es nuestro repositorio falso.
class MockProfileRepository {
  Future<UserProfileModel> fetchUserProfile() async {
    // Simulamos un pequeño retraso, como si estuviera cargando de internet.
    await Future.delayed(const Duration(seconds: 1));

    // Devolvemos datos de prueba que nosotros inventamos.
    return UserProfileModel(
      userId: '12345',
      nombreUsuario: 'atl1god',
      nombrePerfil: 'Atl Yosafat',
      avatarUrl: 'assets/images/avatar_placeholder.png', // Usamos la imagen local
      siguiendoCount: 20,
      seguidoresCount: 50,
    );
  }
}