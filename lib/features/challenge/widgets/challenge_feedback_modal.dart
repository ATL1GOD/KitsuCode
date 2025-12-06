import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import 'package:kitsucode/features/challenge/widgets/report_error_modal.dart';

import 'package:kitsucode/core/utils/app_themes.dart';

import 'package:kitsucode/core/providers/audio_provider.dart';

class ChallengeFeedbackModal extends ConsumerStatefulWidget {
  final bool isCorrect;
  final VoidCallback onContinue;
  final int challengeId;

  const ChallengeFeedbackModal({
    super.key,
    required this.isCorrect,
    required this.onContinue,
    required this.challengeId,
  });

  @override
  ConsumerState<ChallengeFeedbackModal> createState() =>
      _ChallengeFeedbackModalState();
}

class _ChallengeFeedbackModalState
    extends ConsumerState<ChallengeFeedbackModal> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isCorrect) {
        ref.read(audioControllerProvider).playSuccess();
      } else {
        ref.read(audioControllerProvider).playError();
      }
    });
  }

  Future<void> _handleReportError(BuildContext context) async {
    final isChallengeThemeDark =
        Theme.of(context).brightness == Brightness.dark;

    final appTheme = isChallengeThemeDark
        ? AppThemes.darkTheme
        : AppThemes.lightTheme;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) {
        return Theme(
          data: appTheme,
          child: ReportErrorModal(challengeId: widget.challengeId),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isChallengeThemeDark =
        Theme.of(context).brightness == Brightness.dark;

    final appTheme = isChallengeThemeDark
        ? AppThemes.darkTheme
        : AppThemes.lightTheme;

    final Color flagColor = appTheme.colorScheme.secondary;

    final Color successColor = Colors.green.shade600;
    final Color errorColor = Colors.red.shade600;

    final Color titleColor = widget.isCorrect ? successColor : errorColor;

    const String lottieAsset = 'assets/animations/fox_run.json';

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
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
                  widget.isCorrect
                      ? "¡Respuesta Correcta!"
                      : "Respuesta Incorrecta",
                  style: textTheme.headlineMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  widget.isCorrect
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
                  onPressed: widget.onContinue,
                  child: const Text(
                    'CONTINUAR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.flag_outlined, color: flagColor),
              onPressed: () => _handleReportError(context),
              tooltip: 'Reportar un problema',
            ),
          ),
        ],
      ),
    );
  }
}
