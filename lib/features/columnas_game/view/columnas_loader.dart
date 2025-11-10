import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa los modelos y la vista que crearemos
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';
import 'package:kitsucode/features/columnas_game/view/columnas_view.dart';

class ColumnsLoader extends ConsumerWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;
  final String nivelId; // ← ¡AÑADIDO!

  const ColumnsLoader({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId, // ← ¡AÑADIDO!
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // 1. Parsea el JSON usando el factory
      final challenge = ColumnsChallenge.fromJson(challengeContent);

      // 2. Pasa el objeto parseado a la vista del reto
      return ColumnsChallengeView(
        challenge: challenge, 
        retoId: retoId,
        nivelId: nivelId, // ← ¡AÑADIDO!
      );
    } catch (e, stack) {
      // 3. Maneja cualquier error durante el parseo del JSON
      return Scaffold(
        appBar: AppBar(title: const Text('Error de Formato')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error al procesar el reto de columnas:\n$e\n$stack'),
          ),
        ),
      );
    }
  }
}
