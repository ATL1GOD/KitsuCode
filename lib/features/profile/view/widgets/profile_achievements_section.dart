import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:animate_do/animate_do.dart'; // Importación necesaria para la animación
import 'package:go_router/go_router.dart'; // Importación para la navegación

// Importamos los modelos
import 'package:kitsucode/features/profile/model/user_profile_model.dart'; 
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart'; 

// --- CAMBIO AQUÍ: Importamos la tarjeta que SÍ te gusta (estilo Duolingo) ---
import 'package:kitsucode/features/profile/view/widgets/achievement_card.dart';


// --- CAMBIO AQUÍ: Eliminamos la clase "_AchievementCard" que no te gusta ---


// --- WIDGET PRINCIPAL (Mantiene la integración de la mini-tarjeta) ---

class ProfileAchievementsSection extends ConsumerWidget {
  final String userId;
  final bool isCurrentUserProfile;
  final UserProfileModel userProfile;

  const ProfileAchievementsSection({
    super.key,
    required this.userId,
    required this.isCurrentUserProfile,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(userAchievementsProvider(userId));
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    Widget titleWidget(List<dynamic> achievements) {
      // ... (sin cambios)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: colors.secondary,
              ),
              const SizedBox(width: 8),
              Text('Logros', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (achievements.isNotEmpty)
            TextButton(
              onPressed: () {
                // --- NUEVA LÍNEA ---
                // Navegamos a la ruta de logros pasando el userId
                context.push('/profile/$userId/achievements');
              },
              child: Text('Ver todo', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: _GlassCard( // Contenedor principal con efecto cristal
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              achievementsState.when(
                loading: () => titleWidget([]),
                error: (e, s) => titleWidget([]),
                data: (achievements) {
                  final obtainedAchievements = achievements.where((a) => a.obtenido).toList().cast<UserAchievementModel>();
                  return titleWidget(obtainedAchievements);
                },
              ),
              const SizedBox(height: 15),
              achievementsState.when(
                loading: () => const _AchievementsLoadingShimmer(),
                error: (error, stack) => const Center(child: Text('No se pudieron cargar los logros')),
                data: (achievements) {
                  final obtainedAchievements = achievements.where((a) => a.obtenido).toList().cast<UserAchievementModel>();

                  if (obtainedAchievements.isEmpty) {
                    return Padding(
                      // ... (Widget 'sin logros' sin cambios)
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/zorro_oops.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              isCurrentUserProfile
                                  ? '¡Aún no has conseguido logros!'
                                  : '¡${userProfile.nombrePerfil} aún no ha conseguido logros!',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
                    height: 120, // Altura para la tarjeta nueva
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: obtainedAchievements.length,
                      itemBuilder: (context, index) {
                        final achievement = obtainedAchievements[index];

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              // --- CAMBIO AQUÍ: (Tu Problema 2) ---
                              // Siempre transparente para el desenfoque
                              barrierColor: Colors.transparent, 
                              // Llama al diálogo rediseñado
                              builder: (context) => AchievementDetailsDialog(achievement: achievement),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            // --- CAMBIO AQUÍ: Usamos la tarjeta que SÍ te gusta ---
                            child: SizedBox(
                              width: 90, // Ajustamos el ancho para la lista
                              child: AchievementCard(
                                achievement: achievement,
                                colors: colors,
                                // Usamos la vista compacta para la lista horizontal
                                isCompactView: true, 
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS DE SOPORTE ---

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), 
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withOpacity(0.4), 
              borderRadius: BorderRadius.circular(24),
              // Borde eliminado
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AchievementsLoadingShimmer extends StatelessWidget {
  const _AchievementsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    // ... (sin cambios)
    return Shimmer.fromColors(
      baseColor: Colors.grey[400]!,
      highlightColor: Colors.grey[200]!,
      child: SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DIÁLOGO DE DETALLES CALCADO COMO CARTA DE VIDEOJUEGO ---
class AchievementDetailsDialog extends StatelessWidget {
  final UserAchievementModel achievement;

  const AchievementDetailsDialog({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- CAMBIO AQUÍ: Añadimos esta variable ---
    final isUnlocked = achievement.obtenido;

    // Colores basados en primaryLightColorScheme para la carta
    final primaryDark = colors.primary; // B86914
    final secondaryLight = colors.secondaryFixedDim; // FCBF8C

    // --- CAMBIO AQUÍ: (Tu Problema 3) ---
    // Envolvemos todo el modal en el filtro de color
    return ColorFiltered(
      colorFilter: isUnlocked
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
      child: FadeIn( // Animación de entrada (calcar el efecto)
        duration: const Duration(milliseconds: 300),
        child: Dialog(
          // Remueve el fondo del Dialog para que el BackdropFilter funcione en todo el espacio
          backgroundColor: Colors.transparent, 
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), 
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350), 
              decoration: BoxDecoration(
                // Fondo de la carta
                color: colors.surfaceContainerHighest.withOpacity(0.98), 
                borderRadius: BorderRadius.circular(24),
                // Borde brillante como en la referencia
                border: Border.all(color: primaryDark, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: secondaryLight.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // === ZONA SUPERIOR: ARTE Y DEGRADADO ===
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 250, // Altura para el arte
                      width: double.infinity,
                      decoration: BoxDecoration(
                        // Degradado con colores de tu paleta (simulando un fondo dinámico)
                        gradient: LinearGradient(
                          colors: [secondaryLight.withOpacity(0.8), primaryDark.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Imagen de Logro (ajustada para el área de arte)
                          Image.asset(
                            achievement.iconUrl,
                            fit: BoxFit.contain,
                            height: 150,
                          ),
                          // Etiqueta de Rareza (simulando la etiqueta "Legendary")
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.secondary, // Naranja vibrante
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LOGRO ${achievement.id % 3 == 0 ? 'ÉPICO' : 'RARO'}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // === ZONA INFERIOR: TEXTO Y BOTONES ===
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Nombre del logro
                        Text(
                          achievement.nombre,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: colors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Descripción (Texto principal)
                        Text(
                          // --- CAMBIO AQUÍ: Texto condicional ---
                          isUnlocked 
                              ? achievement.descripcion
                              : 'Sigue esforzándote para desbloquear este desafío.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Botón Compartir (usa primary)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            // --- CAMBIO AQUÍ: Deshabilitar si está bloqueado ---
                            onPressed: isUnlocked ? () {
                              // TODO: Implementar lógica para compartir
                              Navigator.of(context).pop(); 
                            } : null, // Esto lo deshabilita
                            icon: const Icon(Icons.share),
                            label: const Text('Compartir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Botón Cerrar (usa outline para un estilo secundario)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cerrar',
                            style: TextStyle(color: colors.outline),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}