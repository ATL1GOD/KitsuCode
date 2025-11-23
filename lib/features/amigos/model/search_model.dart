// lib/features/amigos/model/search_model.dart
class UserSearchPreviewModel {
  final String userId;
  final String nombrePerfil;
  final String nombreUsuario;
  final int idAvatarSeleccionado;
  final String rank;
  final List<int> rankLanguageIds;

  UserSearchPreviewModel({
    required this.userId,
    required this.nombrePerfil,
    required this.nombreUsuario,
    required this.idAvatarSeleccionado,
    required this.rank,
    required this.rankLanguageIds,
  });

  factory UserSearchPreviewModel.fromJson(Map<String, dynamic> json) {
    // Helper para parsear la lista de IDs de forma segura
    List<int> parseLanguageIds(dynamic ids) {
      if (ids is List) {
        // Convierte 'dynamic' a 'int' de forma segura
        return ids.map((id) => (id as num).toInt()).toList();
      }
      return [];
    }

    return UserSearchPreviewModel(
      // Los nombres coinciden con los 'RETURNS TABLE' de la función SQL
      userId: json['userId'] ?? '',
      nombrePerfil: json['nombrePerfil'] ?? 'Usuario',
      nombreUsuario: json['nombreUsuario'] ?? 'N/A',
      idAvatarSeleccionado:
          (json['idAvatarSeleccionado'] as num?)?.toInt() ??
          1, // '?? 1' como fallback
      rank: json['rank'] ?? 'Bronce',
      rankLanguageIds: parseLanguageIds(json['rankLanguageIds']),
    );
  }
}
