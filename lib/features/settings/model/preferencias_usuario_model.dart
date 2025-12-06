class PreferenciasUsuarioModel {
  final String temaVisual;
  final bool sonidoEfectos;
  final double volumenAudio;

  PreferenciasUsuarioModel({
    required this.temaVisual,
    required this.sonidoEfectos,
    required this.volumenAudio,
  });

  factory PreferenciasUsuarioModel.fromJson(Map<String, dynamic> json) {
    return PreferenciasUsuarioModel(
      temaVisual: json['tema_visual'] as String? ?? 'system',
      sonidoEfectos: json['sonido_efectos'] as bool? ?? true,

      volumenAudio: _parseVolumen(json['volumen_audio']),
    );
  }

  static double _parseVolumen(dynamic vol) {
    if (vol is num) {
      return vol.toDouble();
    }
    if (vol is String) {
      return double.tryParse(vol) ?? 0.8;
    }
    return 0.8;
  }

  Map<String, dynamic> toJson() {
    return {
      'tema_visual': temaVisual,
      'sonido_efectos': sonidoEfectos,
      'volumen_audio': volumenAudio,
    };
  }

  PreferenciasUsuarioModel copyWith({
    String? temaVisual,
    bool? sonidoEfectos,
    double? volumenAudio,
  }) {
    return PreferenciasUsuarioModel(
      temaVisual: temaVisual ?? this.temaVisual,
      sonidoEfectos: sonidoEfectos ?? this.sonidoEfectos,
      volumenAudio: volumenAudio ?? this.volumenAudio,
    );
  }

  @override
  String toString() {
    return 'PreferenciasUsuarioModel(temaVisual: $temaVisual, sonidoEfectos: $sonidoEfectos, volumenAudio: $volumenAudio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PreferenciasUsuarioModel &&
        other.temaVisual == temaVisual &&
        other.sonidoEfectos == sonidoEfectos &&
        other.volumenAudio == volumenAudio;
  }

  @override
  int get hashCode =>
      temaVisual.hashCode ^ sonidoEfectos.hashCode ^ volumenAudio.hashCode;
}
