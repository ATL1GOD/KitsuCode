import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/settings/repository/support_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ReportReason {
  confused('El reto es confuso o está mal redactado.'),
  incorrect('Mi respuesta es correcta, pero la marcó como incorrecta.'),
  media('La imagen o el audio no funciona.'),
  other('Otro...');

  final String label;
  const ReportReason(this.label);
}

class ReportErrorModal extends ConsumerStatefulWidget {
  final int challengeId;

  const ReportErrorModal({super.key, required this.challengeId});

  @override
  ConsumerState<ReportErrorModal> createState() => _ReportErrorModalState();
}

class _ReportErrorModalState extends ConsumerState<ReportErrorModal> {
  ReportReason? _selectedReason;
  final _otherController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _showSuccess = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _showSuccess = false;
    });

    if (_selectedReason == null) {
      setState(
        () =>
            _errorMessage = 'Por favor, selecciona un motivo para el reporte.',
      );
      return;
    }

    if (_selectedReason == ReportReason.other &&
        _otherController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'Por favor, describe el problema en la sección "Otro".',
      );
      return;
    }

    final userId = ref.read(authStateProvider).value?.session?.user.id;

    if (userId == null) {
      setState(
        () => _errorMessage =
            'No se pudo identificar tu usuario. Intenta cerrar sesión y volver a entrar.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ref
          .read(supportRepositoryProvider)
          .submitReport(
            userId: userId,
            type: _selectedReason!.label,
            description: _selectedReason == ReportReason.other
                ? _otherController.text.trim()
                : "Reporte automático del Reto ${widget.challengeId}",
          );

      if (mounted) {
        setState(() => _showSuccess = true);

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage =
              'Error de conexión. No se pudo enviar tu reporte. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: size.height * 0.75),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.surfaceContainerHighest,
                  colors.surfaceContainerLow,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.secondary.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _showSuccess
                ? _buildSuccessView(colors, textTheme)
                : _buildFormView(colors, textTheme),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic);
  }

  Widget _buildSuccessView(ColorScheme colors, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡Reporte enviado!',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Gracias por ayudarnos a mejorar KitsuCode 🦊',
          style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).scale();
  }

  Widget _buildFormView(ColorScheme colors, TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_outlined,
              size: 32,
              color: colors.onErrorContainer,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "¿Encontraste un problema?",
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            "Ayúdanos a mejorar KitsuCode 🦊",
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.error, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).shake(hz: 2),

          ...ReportReason.values.map((reason) {
            final selected = _selectedReason == reason;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  InkWell(
                        onTap: _loading
                            ? null
                            : () {
                                setState(() {
                                  _selectedReason = reason;
                                  _errorMessage = null;
                                });
                              },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primaryContainer
                                : colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? colors.primary
                                  : colors.outlineVariant,
                              width: selected ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                size: 22,
                              ),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  reason.label,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? colors.onPrimaryContainer
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate(target: selected ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.02, 1.02),
                        duration: 200.ms,
                      ),
            );
          }),

          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            child: _selectedReason == ReportReason.other
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child:
                        TextField(
                              controller: _otherController,
                              maxLines: 3,
                              maxLength: 500,
                              enabled: !_loading,
                              onChanged: (value) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colors.surfaceContainerHigh,
                                hintText: "Describe el problema...",
                                hintStyle: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: -0.1, curve: Curves.easeOutCubic),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cancelar",
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onPrimary,
                          ),
                        )
                      : Text(
                          "Enviar",
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
