class UserSearchPreviewModel {
  final String userId;
  final String nombrePerfil;
  final String nombreUsuario;
  final int idAvatarSeleccionado;
  final String rank;

  UserSearchPreviewModel({
    required this.userId,
    required this.nombrePerfil,
    required this.nombreUsuario,
    required this.idAvatarSeleccionado,
    required this.rank,
  });

  factory UserSearchPreviewModel.fromJson(Map<String, dynamic> json) {
    return UserSearchPreviewModel(
      // Los nombres coinciden con los 'RETURNS TABLE' de la función SQL
      userId: json['userId'],
      nombrePerfil: json['nombrePerfil'],
      nombreUsuario: json['nombreUsuario'],
      idAvatarSeleccionado:
          json['idAvatarSeleccionado'] ?? 1, // '?? 1' como fallback
      rank: json['rank'] ?? 'Bronce', // Añadido el campo rank con fallback
    );
  }
}
