import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AchievementModal extends StatelessWidget {
  final UserAchievementModel achievement;

  const AchievementModal({super.key, required this.achievement});

  Color _getBorderColor(int id, ColorScheme colors) {
    switch (id % 3) {
      case 0: return colors.secondary;
      case 1: return colors.primary;
      case 2: return const Color(0xFF00FF00);
      default: return colors.outline;
    }
  }

  String _getRarityText(int id) {
    switch (id % 3) {
      case 0: return 'ÉPICO';
      case 1: return 'COMÚN';
      case 2: return 'LEGENDARIO';
      default: return 'DESCONOCIDO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = _getBorderColor(achievement.id, colors);
    final rarityText = _getRarityText(achievement.id);
    final isUnlocked = achievement.obtenido;
    final lockedColor = colors.onSurfaceVariant.withOpacity(0.5);

    Widget img = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: Image.asset(
        achievement.iconUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );

    if (!isUnlocked) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: img,
      );
    }

    // FINAL ANIMATION
    final animatedImg = isUnlocked
        ? img
            .animate()
            .scale(
              begin: const Offset(1.3, 1.3),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .shake(
              duration: 600.ms,
              hz: 3,
              offset: const Offset(3, 3),
            )
            .then()
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 250.ms,
              curve: Curves.easeOut,
            )
        : img;

    final aura = isUnlocked
        ? Icon(Icons.auto_awesome, size: 120, color: borderColor.withOpacity(0.35))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
            )
        : const SizedBox.shrink();

    // SOLUCIÓN FINAL: AlertDialog Transparente
    return AlertDialog(
        // 1. Fondo transparente para que se vea el barrierColor (oscuro)
        backgroundColor: Colors.transparent,
        // 2. Eliminar padding interno
        contentPadding: EdgeInsets.zero,
        // 3. Eliminar la forma por defecto del AlertDialog
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),

        content: Stack(
          alignment: Alignment.center,
          children: [
            aura,
            Container(
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.surface, // El color opaco de TU tarjeta
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked
                        ? borderColor.withOpacity(0.7)
                        : colors.shadow.withOpacity(0.15),
                    blurRadius: isUnlocked ? 30 : 10,
                    spreadRadius: isUnlocked ? 5 : 2,
                  ),
                ],
              ),
              child: Column(
                // 4. Clave: Asegura que el contenedor solo ocupe el tamaño necesario
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text("Logro", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ID: ${achievement.id}",
                                style: TextStyle(color: isUnlocked ? colors.onSurfaceVariant : lockedColor)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? borderColor.withOpacity(0.8)
                                    : lockedColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rarityText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? colors.onPrimary : colors.surface,
                                ),
                              ),
                            ),
                            Text(
                              isUnlocked ? "¡OBTENIDO!" : "BLOQUEADO",
                              style: TextStyle(
                                color: isUnlocked ? const Color(0xFF00FF00) : lockedColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // CARD CONTENT
                  Container(
                    width: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isUnlocked ? borderColor : lockedColor,
                        width: 4,
                      ),
                      color: colors.surface,
                    ),
                    child: Column(
                      children: [
                        animatedImg,
                        const SizedBox(height: 12),
                        Text(
                          achievement.nombre.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isUnlocked ? colors.onSurface : lockedColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          isUnlocked ? Icons.star : Icons.lock_outline,
                          color: isUnlocked ? borderColor : lockedColor,
                          size: 24,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Column(
                            children: [
                              Text(
                                isUnlocked
                                    ? "Obtuviste este logro por:"
                                    : "Para obtener este logro, necesitas:",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? colors.onSurfaceVariant : lockedColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                achievement.descripcion,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isUnlocked ? colors.onSurfaceVariant : lockedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CLOSE BUTTON
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("Cerrar", style: TextStyle(color: colors.onPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}