import 'package:kitsucode/features/challenge/view/feedback/challenge_failure_view.dart'
    show RecursoModel;

class ColumnsChallenge {
  final List<ColumnPair> pares;

  final List<RecursoModel> recursos;

  ColumnsChallenge({required this.pares, required this.recursos});

  factory ColumnsChallenge.fromJson(Map<String, dynamic> json) {
    var paresList = json['pares'] as List;
    List<ColumnPair> pares = paresList
        .map((i) => ColumnPair.fromJson(i as Map<String, dynamic>))
        .toList();

    final List<dynamic> recursosJson = json['recursos'] as List<dynamic>? ?? [];
    final List<RecursoModel> recursosList = recursosJson
        .map((r) => RecursoModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return ColumnsChallenge(pares: pares, recursos: recursosList);
  }
}

class ColumnPair {
  final int id;
  final String termino;
  final String definicion;

  ColumnPair({
    required this.id,
    required this.termino,
    required this.definicion,
  });

  factory ColumnPair.fromJson(Map<String, dynamic> json) {
    return ColumnPair(
      id: json['id'] as int,
      termino: json['termino'] as String,
      definicion: json['definicion'] as String,
    );
  }
}

class ChallengeItem {
  final int pairId;
  final String text;
  final ItemType type;

  ChallengeItem({required this.pairId, required this.text, required this.type});
}

enum ItemType { termino, definicion }
