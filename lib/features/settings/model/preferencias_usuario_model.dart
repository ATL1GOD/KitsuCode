
class PreferenciasUsuarioModel {
  final String temaVisual; // 'system', 'light', 'dark'
  final bool sonidoEfectos;
  final double volumenAudio;

  PreferenciasUsuarioModel({
    required this.temaVisual,
    required this.sonidoEfectos,
    required this.volumenAudio,
  });

  factory PreferenciasUsuarioModel.fromJson(Map<String, dynamic> json) {
    return PreferenciasUsuarioModel(
      // --- ¡CAMBIO! ---
      // El valor por defecto ahora es 'system'
      temaVisual: json['tema_visual'] as String? ?? 'system', 
      sonidoEfectos: json['sonido_efectos'] as bool? ?? true,
      // El JSON que pasaste tenía "1.00" como string, así que
      // parseamos 'num' O 'String' para ser seguros.
      volumenAudio: _parseVolumen(json['volumen_audio']),
    );
  }

  // Helper robusto para el volumen
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
  
  // ... (El resto de métodos ==, hashCode, toString se quedan igual) ...
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
  int get hashCode => temaVisual.hashCode ^ sonidoEfectos.hashCode ^ volumenAudio.hashCode;
}