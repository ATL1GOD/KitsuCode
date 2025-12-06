import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/puzzle_game/provider/puzzle_provider.dart';
import 'package:kitsucode/features/puzzle_game/view/puzzle_view.dart';

class PuzzleLoaderPage extends StatelessWidget {
  final Map<String, dynamic> challengeContent;
  final String retoId;
  final String nivelId;

  const PuzzleLoaderPage({
    super.key,
    required this.challengeContent,
    required this.retoId,
    required this.nivelId,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        puzzleProvider.overrideWith(
          (ref) => PuzzleNotifier(
            challengeContent,
            int.parse(retoId),
            int.parse(nivelId),
          ),
        ),
      ],

      child: const PuzzleView(),
    );
  }
}
