// lib/features/challenge/widgets/challenge_feedback_modal.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Modal de reporte
import 'package:kitsucode/features/challenge/widgets/report_error_modal.dart';

// Tema principal de KitsuCode
import 'package:kitsucode/core/utils/app_themes.dart';

class ChallengeFeedbackModal extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onContinue;
  final int challengeId;

  const ChallengeFeedbackModal({
    super.key,
    required this.isCorrect,
    required this.onContinue,
    required this.challengeId,
  });

  Future<void> _handleReportError(BuildContext context) async {
    // Determinar si el tema actual del reto es claro u oscuro
    final isChallengeThemeDark =
        Theme.of(context).brightness == Brightness.dark;

    // Tema principal (naranja de KitsuCode)
    final appTheme =
        isChallengeThemeDark ? AppThemes.darkTheme : AppThemes.lightTheme;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) {
        return Theme(
          data: appTheme,
          child: ReportErrorModal(
            challengeId: challengeId,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determinar si el tema actual del reto es claro u oscuro
    final isChallengeThemeDark =
        Theme.of(context).brightness == Brightness.dark;

    // Tema principal (naranja de KitsuCode)
    final appTheme =
        isChallengeThemeDark ? AppThemes.darkTheme : AppThemes.lightTheme;

    final Color flagColor = appTheme.colorScheme.secondary;

    // Estilos de resultado
    final Color successColor = Colors.green.shade600;
    final Color errorColor = Colors.red.shade600;
    final Color titleColor = isCorrect ? successColor : errorColor;

    const String lottieAsset = 'assets/animations/fox_run.json';

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // Fondo del modal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
                .copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset(lottieAsset, repeat: true),
                ),
                const SizedBox(height: 20),

                Text(
                  isCorrect ? "¡Respuesta Correcta!" : "Respuesta Incorrecta",
                  style: textTheme.headlineMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  isCorrect
                      ? "¡Sigue así! Lo estás haciendo muy bien."
                      : "No te preocupes. ¡Inténtalo de nuevo!",
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: onContinue,
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón de bandera (reportar)
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                Icons.flag_outlined,
                color: flagColor,
              ),
              onPressed: () => _handleReportError(context),
              tooltip: 'Reportar un problema',
            ),
          ),
        ],
      ),
    );
  }
}