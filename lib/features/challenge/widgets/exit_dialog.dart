import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';

void showExitDialog(BuildContext context, WidgetRef ref) {
  HapticFeedback.lightImpact();
  ref.read(audioControllerProvider).playClick();

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  final titleStyle = textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
  );
  final contentStyle = textTheme.bodyLarge;
  final buttonTextStyle = textTheme.labelLarge?.copyWith(
    fontWeight: FontWeight.bold,
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),

        title: Text(
          '¿Quieres salir del reto?',
          textAlign: TextAlign.center,
          style: titleStyle,
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/images/home/alerta.webp",
              height: 220,
              cacheHeight: 440,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu progreso en este reto se perderá.',
              textAlign: TextAlign.center,
              style: contentStyle,
            ),
          ],
        ),

        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              textStyle: buttonTextStyle,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(audioControllerProvider).playClick();
              Navigator.pop(context);
            },
            child: const Text('CANCELAR'),
          ),

          const SizedBox(width: 80),

          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: buttonTextStyle,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(audioControllerProvider).playClick();

              resumeMusicAfterChallenge(ref);

              Navigator.pop(context);
              context.pop();
            },
            child: const Text('SALIR'),
          ),
        ],
      );
    },
  );
}
