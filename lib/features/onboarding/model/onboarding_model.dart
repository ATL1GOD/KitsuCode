class OnboardingResultModel {
  final String titulo;
  final String subtitulo;
  final String descripcion;
  final String imagenUrl;
  final int nivelInterno;

  OnboardingResultModel({
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
    required this.imagenUrl,
    required this.nivelInterno,
  });

  factory OnboardingResultModel.fromJson(Map<String, dynamic> json) {
    return OnboardingResultModel(
      titulo: json['titulo'] ?? '',
      subtitulo: json['subtitulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen_url'] ?? '',
      nivelInterno: json['nivel_interno'] ?? 1,
    );
  }
}
