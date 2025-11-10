import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:lottie/lottie.dart';

// Esta vista es un placeholder que sigue el diseño
class SupportView extends ConsumerWidget {
  const SupportView({super.key});

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
          final dynamicColor = AllStatsView.getHeaderColor(profile, colors);

          return Stack(
            children: [
              // --- FONDO ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dynamicColor.withAlpha(100),
                      colors.surfaceContainerLowest,
                    ],
                    stops: const [0.0, 0.7]
                  ),
                ),
              ),
              // --- ANIMACIÓN LOTTIE ---
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.secondaryFixedDim.withOpacity(0.8),
                  BlendMode.srcIn, 
                ),
                child: Lottie.asset(
                  'assets/animations/spring.json', 
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
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
                          Text(
                            '¿Encontraste un error o tienes una idea?',
                            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '¡Cuéntanos! Tu feedback nos ayuda a mejorar KitsuCode.',
                            style: textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
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
                          const SizedBox(height: 20),
                          FilledButton.icon(
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