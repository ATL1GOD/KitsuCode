class UserSearchPreviewModel {
  final String userId;
  final String nombrePerfil;
  final String nombreUsuario;
  final int idAvatarSeleccionado;

  UserSearchPreviewModel({
    required this.userId,
    required this.nombrePerfil,
    required this.nombreUsuario,
    required this.idAvatarSeleccionado,
  });

  factory UserSearchPreviewModel.fromJson(Map<String, dynamic> json) {
    return UserSearchPreviewModel(
      // Los nombres coinciden con los 'RETURNS TABLE' de la función SQL
      userId: json['userId'],
      nombrePerfil: json['nombrePerfil'],
      nombreUsuario: json['nombreUsuario'],
      idAvatarSeleccionado:
          json['idAvatarSeleccionado'] ?? 1, // '?? 1' como fallback
    );
  }
}
