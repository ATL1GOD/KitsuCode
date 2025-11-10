// lib/features/codigo_game/view/codigo_loader.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa los modelos y la vista que crearemos
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';
import 'package:kitsucode/features/codigo_game/view/codigo_view.dart';

class CodigoLoader extends ConsumerWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;
  final String nivelId; // ← ¡AÑADIDO!

  const CodigoLoader({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId, // ← ¡AÑADIDO!
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      // 1. Parsea el JSON usando el factory
      final challenge = CodigoChallenge.fromJson(challengeContent);

      // 2. Pasa el objeto parseado a la vista del reto
      return CodigoChallengeView(
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
            child: Text('Error al procesar el reto de código:\n$e\n$stack'),
          ),
        ),
      );
    }
  }
}
