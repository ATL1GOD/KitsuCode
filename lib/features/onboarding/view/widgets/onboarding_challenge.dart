import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/model/puzzle_challenge_model.dart';
import 'package:kitsucode/features/columnas_game/view/columnas_view.dart';
import 'package:kitsucode/features/columnas_game/model/columnas_model.dart';
import 'package:kitsucode/features/codigo_game/view/codigo_view.dart';
import 'package:kitsucode/features/codigo_game/model/codigo_model.dart';
import 'package:kitsucode/features/quiz_game/view/widgets/quiz_view.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';

class OnboardingGameRenderer extends ConsumerWidget {
  final int tipoReto;
  final dynamic content;
  final Function(bool) onFinished;

  const OnboardingGameRenderer({
    super.key,
    required this.tipoReto,
    required this.content,
    required this.onFinished,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (tipoReto) {
      case 1:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final model = PuzzleChallengeModel.fromJson(content);
          ref.read(puzzleProvider.notifier).loadChallengeFromModel(model);
        });
        return PuzzleView(onOnboardingFinished: onFinished);

      case 2:
        final model = ColumnsChallenge.fromJson(content);
        return ColumnsChallengeView(
          challenge: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: onFinished,
        );

      case 3:
        final model = CodigoChallenge.fromJson(content);
        return CodigoChallengeView(
          challenge: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: onFinished,
        );

      case 4:
        final model = QuizData.fromJson(content);
        return QuizPage(
          mydata: model,
          retoId: "onboarding",
          nivelId: "0",
          onOnboardingFinished: onFinished,
        );

      default:
        return Center(
          child: Text(
            "Tipo de reto desconocido: $tipoReto",
            style: const TextStyle(color: Colors.red),
          ),
        );
    }
  }
}
