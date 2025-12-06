import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';
import 'package:kitsucode/features/codigo_game/view/codigo_view.dart';

class CodigoLoader extends ConsumerWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;
  final String nivelId;

  const CodigoLoader({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final challenge = CodigoChallenge.fromJson(challengeContent);

      return CodigoChallengeView(
        challenge: challenge,
        retoId: retoId,
        nivelId: nivelId,
      );
    } catch (e, stack) {
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
