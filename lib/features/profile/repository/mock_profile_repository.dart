// // lib/features/profile/repository/mock_profile_repository.dart

// import 'package:kitsucode/features/profile/model/user_profile_model.dart';

// // Este es el repositorio falso.
// class MockProfileRepository {
//   // Le damos "memoria" con una variable que guardará los datos de prueba.
//   UserProfileModel _mockData = UserProfileModel(
//     userId: '12345',
//     nombreUsuario: 'atl1god',
//     nombrePerfil: 'Atl Yosafat',
//     avatarUrl: 'assets/images/login_zorro.png',
//     siguiendoCount: 23,
//     seguidoresCount: 50,
//   );

//   // El método para obtener los datos ahora devuelve la variable con memoria.
//   Future<UserProfileModel> fetchUserProfile() async {
//     await Future.delayed(const Duration(seconds: 1));
//     return _mockData;
//   }

//   // ¡NUEVO! Un método para actualizar los datos.
//   Future<void> updateUserProfile({
//     required String userId,
//     String? newName,
//     String? newAvatar,
//   }) async {
//     // Simulamos que estamos guardando en la base de datos.
//     await Future.delayed(const Duration(seconds: 2));

//     // Actualizamos nuestra variable en memoria.
//     _mockData = UserProfileModel(
//       userId: _mockData.userId,
//       nombreUsuario: _mockData.nombreUsuario,
//       nombrePerfil: newName ?? _mockData.nombrePerfil, // Si llega un nombre nuevo, lo usamos.
//       avatarUrl: newAvatar ?? _mockData.avatarUrl,   // Si llega un avatar nuevo, lo usamos.
//       siguiendoCount: _mockData.siguiendoCount,
//       seguidoresCount: _mockData.seguidoresCount,
//     );
//   }
// }