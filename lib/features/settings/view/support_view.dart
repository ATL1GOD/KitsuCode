// lib/features/settings/view/support_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/shared/widgets/static_settings_background.dart';
import 'package:animate_do/animate_do.dart';
import 'package:kitsucode/features/settings/repository/support_repository.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart'; // ✅ fallback de color

enum ReportType { bug, suggestion, other }

class SupportView extends ConsumerStatefulWidget {
  const SupportView({super.key});

  @override
  ConsumerState<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends ConsumerState<SupportView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportType _selectedReportType = ReportType.bug;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ color dinámico desde BD (lista de avatares); si aún no carga, usa fallback
  Color _computeDynamicColor(UserProfileModel profile, ColorScheme colors) {
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    if (avatarsList.isNotEmpty) {
      return getAvatarColorById(profile.idAvatarSeleccionado, avatarsList);
    }
    return AllStatsView.getHeaderColor(profile, colors);
  }

  void _submitReport(String userId, String type) async {
    if (!_formKey.currentState!.validate()) {
      showWarningSnackbar(context, 'Campos incompletos', 'Por favor, describe tu reporte.');
      return;
    }

    setState(() => _isLoading = true);
    showHelpSnackbar(context, 'Enviando...', 'Estamos procesando tu reporte. No cierres la app.');

    try {
      await ref.read(supportRepositoryProvider).submitReport(
            userId: userId,
            type: type,
            description: _descriptionController.text.trim(),
          );

      if (mounted) {
        showSuccessSnackbar(context, '¡Enviado!', 'Gracias por tu feedback. Lo revisaremos pronto.');
        context.pop();
        _descriptionController.clear();
        setState(() {
          _selectedReportType = ReportType.bug;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(
          context,
          'Error de Conexión',
          'No se pudo enviar el reporte. Verifica tu conexión o intenta más tarde.',
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentAuthUserId = ref.watch(authStateProvider).value?.session?.user.id;

    if (currentAuthUserId == null) {
      return const Scaffold(body: Center(child: Text("Error de autenticación")));
    }

    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = _computeDynamicColor(profile, colors); // ✅ usar color real

          return Stack(
            children: [
              // Fondo estático compartido (sin cambios)
              StaticSettingsBackground(profile: profile, colors: colors),

              SafeArea(
                child: Column(
                  children: [
                    // Barra superior — borde con dynamicColor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: colors.surface.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(color: dynamicColor.withAlpha(140)),
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Ayuda y Sugerencias',
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Formulario
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(20.0),
                          children: [
                            FadeInDown(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                '¿Encontraste un error o tienes una idea?',
                                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FadeInDown(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                '¡Cuéntanos! Tu feedback nos ayuda a mejorar KitsuCode.',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SegmentedButton (usa dynamicColor)
                            FadeInDown(
                              delay: const Duration(milliseconds: 300),
                              child: SegmentedButton<ReportType>(
                                segments: const [
                                  ButtonSegment(
                                    value: ReportType.bug,
                                    label: Text('Bug'),
                                    icon: Icon(Icons.bug_report_outlined),
                                  ),
                                  ButtonSegment(
                                    value: ReportType.suggestion,
                                    label: Text('Sugerencia'),
                                    icon: Icon(Icons.lightbulb_outline),
                                  ),
                                  ButtonSegment(
                                    value: ReportType.other,
                                    label: Text('Otro'),
                                    icon: Icon(Icons.help_outline),
                                  ),
                                ],
                                selected: {_selectedReportType},
                                onSelectionChanged: (Set<ReportType> newSelection) {
                                  setState(() {
                                    _selectedReportType = newSelection.first;
                                  });
                                },
                                style: SegmentedButton.styleFrom(
                                  backgroundColor: colors.surfaceContainerHigh,
                                  foregroundColor: colors.onSurface,
                                  side: BorderSide(color: dynamicColor.withAlpha(170), width: 1.2),
                                  textStyle: textTheme.labelMedium?.copyWith(fontSize: 12.5),
                                  selectedForegroundColor: colors.onPrimary,
                                  selectedBackgroundColor: dynamicColor,
                                  // ✅ overlayColor aquí es Color?, no WidgetStateProperty
                                  overlayColor: dynamicColor.withAlpha(40),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Campo de texto con aura (usa dynamicColor)
                            FadeInDown(
                              delay: const Duration(milliseconds: 400),
                              child: _AuraTextFieldWrapper(
                                dynamicColor: dynamicColor,
                                child: TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 8,
                                  validator: (value) =>
                                      value == null || value.isEmpty || value.trim().isEmpty
                                          ? 'Por favor, describe tu problema o idea.'
                                          : null,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe tu reporte o sugerencia aquí...',
                                    hintStyle: textTheme.bodyLarge?.copyWith(
                                      // ✅ sin deprecación
                                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Botón enviar (usa dynamicColor)
                            FadeInDown(
                              delay: const Duration(milliseconds: 500),
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: dynamicColor,
                                  foregroundColor: colors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => _submitReport(
                                          currentAuthUserId,
                                          _selectedReportType.name,
                                        ),
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(_isLoading ? 'Enviando...' : 'Enviar Feedback'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Wrapper con aura (sin cambios funcionales; ya usa dynamicColor)
class _AuraTextFieldWrapper extends StatelessWidget {
  final Widget child;
  final Color dynamicColor;

  const _AuraTextFieldWrapper({
    required this.child,
    required this.dynamicColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: c.surface.withAlpha(242),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dynamicColor.withAlpha(153)),
        boxShadow: [
          BoxShadow(
            color: dynamicColor.withAlpha(64),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
