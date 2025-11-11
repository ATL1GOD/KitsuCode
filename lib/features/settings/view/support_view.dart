import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/settings/view/widgets/animated_settings_background.dart';
import 'package:animate_do/animate_do.dart';

// Esta vista es un placeholder que sigue el diseño
class SupportView extends ConsumerWidget {
  const SupportView({super.key});

  // Helper para obtener el color dinámico
  Color _getDynamicColor(UserProfileModel profile, ColorScheme colors) {
    final avatar = profile.avatarUrl.toLowerCase();
    if (avatar.contains('tiburon')) return const Color(0xFF0097A7);
    if (avatar.contains('zorro')) return const Color(0xFFE65100);
    if (avatar.contains('gato')) return const Color(0xFF7B1FA2);
    if (avatar.contains('león') || avatar.contains('leon')) return const Color(0xFFF57F17);
    if (avatar.contains('panda')) return const Color(0xFF2E7D32);
    return colors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentAuthUserId = ref.watch(authStateProvider).value!.session!.user.id;
    final profileState = ref.watch(userProfileByIdProvider(currentAuthUserId));

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (profile) {
          final dynamicColor = _getDynamicColor(profile, colors);
          
          return Stack(
            children: [
              // --- FONDO ANIMADO OPTIMIZADO ---
              AnimatedSettingsBackground(
                profile: profile,
                colors: colors,
              ),
              
              // --- CONTENIDO ---
              SafeArea(
                child: Column(
                  children: [
                    // --- BARRA SUPERIOR ---
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
                                border: Border.all(color: colors.outlineVariant.withAlpha(130))
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

                    // --- FORMULARIO DE SOPORTE (Simple) ---
                    Expanded(
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
                              style: textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInDown(
                            delay: const Duration(milliseconds: 300),
                            child: TextField(
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: 'Escribe tu reporte o sugerencia aquí...',
                                filled: true,
                                fillColor: colors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: colors.outlineVariant),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FadeInDown(
                            delay: const Duration(milliseconds: 400),
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: dynamicColor,
                                foregroundColor: colors.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                // TODO: Lógica para enviar el formulario a la tabla 'reporte_error'
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('¡Reporte enviado! Gracias.'))
                                );
                                context.pop();
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Enviar Feedback'),
                            ),
                          ),
                        ],
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