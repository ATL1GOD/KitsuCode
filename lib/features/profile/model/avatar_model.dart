class AvatarModel {
  final int id;
  final String nombre;
  final String descripcion;
  final String assetPath;
  final String colorPrimario;
  final String tipo;
  final String? requisitoDescripcion;
  final int orden;
  final bool desbloqueado;

  AvatarModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.assetPath,
    required this.colorPrimario,
    required this.tipo,
    this.requisitoDescripcion,
    required this.orden,
    required this.desbloqueado,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? 'Avatar',
      descripcion: json['descripcion'] as String? ?? 'Sin descripción',
      assetPath:
          json['assetpath'] as String? ?? 'assets/images/login_zorro.webp',
      colorPrimario: json['colorprimario'] as String? ?? '0xFFE65100',
      tipo: json['tipo'] as String? ?? 'comun',
      requisitoDescripcion: json['requisitodescripcion'] as String?,
      orden: json['orden'] as int? ?? 0,
      desbloqueado: json['desbloqueado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'assetpath': assetPath,
      'colorprimario': colorPrimario,
      'tipo': tipo,
      'requisitodescripcion': requisitoDescripcion,
      'orden': orden,
      'desbloqueado': desbloqueado,
    };
  }

  bool get esComun => tipo == 'comun';
  bool get esEspecial => tipo == 'especial';

  AvatarModel copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    String? assetPath,
    String? colorPrimario,
    String? tipo,
    String? requisitoDescripcion,
    int? orden,
    bool? desbloqueado,
  }) {
    return AvatarModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      assetPath: assetPath ?? this.assetPath,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      tipo: tipo ?? this.tipo,
      requisitoDescripcion: requisitoDescripcion ?? this.requisitoDescripcion,
      orden: orden ?? this.orden,
      desbloqueado: desbloqueado ?? this.desbloqueado,
    );
  }

  @override
  String toString() {
    return 'AvatarModel(id: $id, nombre: $nombre, tipo: $tipo, desbloqueado: $desbloqueado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvatarModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
