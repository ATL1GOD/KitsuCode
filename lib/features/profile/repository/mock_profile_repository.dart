// lib/features/profile/repository/mock_profile_repository.dart

import 'dart:async';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  
  final _profileStreamController = StreamController<UserProfileModel>.broadcast();

  UserProfileModel _mockData = UserProfileModel(
    userId: '12345',
    nombreUsuario: 'atl1god',
    correo: 'atl.yosafat@example.com',
    nombrePerfil: 'Atl Yosafat',
    avatarUrl: 'assets/images/login_zorro.png',
    siguiendoCount: 23,
    seguidoresCount: 50,
    cambiosAvatarHoy: 0,
    cambiosNombrePerfilEsteMes: 0,
  );

  // El constructor ahora no necesita añadir los datos al stream, 
  // el nuevo watchUserProfileById se encargará.
  MockProfileRepository();

  // --- CAMBIO CLAVE AQUÍ ---
  @override
  Stream<UserProfileModel> watchUserProfileById(String userId) async* {
    // 1. Inmediatamente emitimos los datos actuales a quien se suscriba.
    yield _mockData;

    // 2. Nos quedamos escuchando futuros cambios en el stream controller.
    // Esto es para que la UI reaccione cuando actualicemos el perfil.
    await for (final updatedProfile in _profileStreamController.stream) {
      yield updatedProfile;
    }
  }
  
  @override
  Future<UserProfileModel> fetchUserProfileById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockData;
  }

  @override
  Future<UserProfileModel> fetchUserProfile() async {
    return fetchUserProfileById('12345');
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    String? newName,
    String? newAvatar,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    _mockData = _mockData.copyWith(
      nombrePerfil: newName,
      avatarUrl: newAvatar,
      cambiosNombrePerfilEsteMes: newName != null ? _mockData.cambiosNombrePerfilEsteMes + 1 : _mockData.cambiosNombrePerfilEsteMes,
      cambiosAvatarHoy: newAvatar != null ? _mockData.cambiosAvatarHoy + 1 : _mockData.cambiosAvatarHoy,
    );
    
    // Añadimos los datos actualizados al stream para que 'watchUserProfileById' los emita.
    _profileStreamController.add(_mockData);
  }

  @override
  Future<UserStatsModel> fetchUserStatsById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return UserStatsModel(
      retosCompletados: 42,
      rachaDias: 15,
      porcentajeAciertos: 88.5,
      porcentajeFallos: 11.5,
    );
  }

  @override
  Future<List<UserAchievementModel>> fetchUserAchievementsById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      UserAchievementModel(id: 1, nombre: 'Pionero', descripcion: 'Completaste tu primer reto.', iconUrl: 'assets/images/prueba.jpg', obtenido: true),
      UserAchievementModel(id: 2, nombre: 'Constancia', descripcion: 'Mantuviste una racha de 7 días.', iconUrl: 'assets/images/prueba.jpg', obtenido: true),
      UserAchievementModel(id: 3, nombre: 'Invencible', descripcion: 'Completa un reto sin errores.', iconUrl: 'assets/images/prueba.jpg', obtenido: true),
      UserAchievementModel(id: 4, nombre: 'Maestro del Login', descripcion: 'Iniciaste sesión 10 veces.', iconUrl: 'assets/images/prueba.jpg', obtenido: true),
      UserAchievementModel(id: 5, nombre: 'Explorador', descripcion: 'Visita 5 perfiles diferentes.', iconUrl: 'assets/images/prueba.jpg', obtenido: false),
      UserAchievementModel(id: 6, nombre: 'Colaborador', descripcion: 'Deja 10 comentarios en retos.', iconUrl: 'assets/images/prueba.jpg', obtenido: true),
    ];
  }

  @override
  Future<bool> isFollowing(String followedUserId) async {
    return Future.value(false);
  }

  @override
  Future<bool> toggleFollow(String followedUserId) async {
    return Future.value(true);
  }
  
  @override
  Future<UserStatsModel> fetchUserStats() async {
    return fetchUserStatsById('12345');
  }
  
  @override
  Future<List<UserAchievementModel>> fetchUserAchievements() async {
    return fetchUserAchievementsById('12345');
  }
}