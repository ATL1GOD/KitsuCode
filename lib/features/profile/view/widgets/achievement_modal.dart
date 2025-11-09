import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kitsucode/features/profile/utils/achievement_helpers.dart'; 

class AchievementModal extends StatelessWidget {
  final UserAchievementModel achievement;

  const AchievementModal({super.key, required this.achievement});

  static Future<void> show(BuildContext context, UserAchievementModel achievement) async {
    // ✅ Capturamos el tema ANTES de abrir el modal
    final theme = Theme.of(context);
    
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          // ✅✅✅ CLAVE: Envolvemos en Theme para forzar el tema correcto
          return Theme(
            data: theme, // Usamos el tema capturado
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: _ModalContent(achievement: achievement),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ModalContent(achievement: achievement);
  }
}

// ✅ Separamos el contenido en su propio widget
class _ModalContent extends StatelessWidget {
  final UserAchievementModel achievement;

  const _ModalContent({required this.achievement});



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String raridad = achievement.raridad; // Obtenemos la rareza real
    final Color borderColor = getRarityColor(raridad); // Color según rareza
    final String rarityText = getRarityText(raridad); // Texto según rareza
    final isUnlocked = achievement.obtenido;
    final lockedColor = colors.onSurfaceVariant.withOpacity(0.5);

    // ✅ Imagen con filtro gris aplicado DENTRO del ClipRRect
    Widget img = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: ColorFiltered(
        colorFilter: isUnlocked
            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: Image.asset(
          achievement.iconUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );

    // ✅ SIEMPRE mostramos animaciones (sin importar si está desbloqueado)
    final animatedImg = img
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
        );

    // ✅ Aura con color según estado (gris si está bloqueado)
    final aura = isUnlocked
        ? Icon(Icons.auto_awesome, size: 120, color: borderColor.withOpacity(0.35))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
            )
        : Icon(Icons.auto_awesome, size: 120, color: Colors.grey.shade600.withOpacity(0.5)) // ✅ Más visible en gris
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
            );

    // ✅✅✅ SOLUCIÓN: Container negro semitransparente + GestureDetector
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        // ✅ ESTO ES LO QUE FALTABA - Fondo negro semitransparente
        color: Colors.black.withOpacity(0.7),
        child: GestureDetector(
          onTap: () {}, // Evita cerrar al tocar el modal
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  aura,
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // ✅ Gris cálido si está bloqueado, blanco si está desbloqueado
                      color: isUnlocked ? colors.surface : const Color(0xFFBDBDBD), // Gris cálido
                      boxShadow: [
                        BoxShadow(
                          // ✅ Sombra gris si está bloqueado, color vibrante si está desbloqueado
                          color: isUnlocked
                              ? borderColor.withOpacity(0.7)
                              : Colors.grey.shade600.withOpacity(0.6), // ✅ Más visible
                          blurRadius: isUnlocked ? 30 : 20,
                          spreadRadius: isUnlocked ? 5 : 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text("Logro", style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "ID: ${achievement.id}",
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant, // ✅ Siempre con color normal
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: borderColor.withOpacity(0.8), // ✅ Siempre con color bonito
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rarityText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: colors.onPrimary, // ✅ Siempre con color normal
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      isUnlocked ? "¡OBTENIDO!" : "BLOQUEADO",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: isUnlocked ? const Color(0xFF00FF00) : lockedColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isUnlocked ? borderColor : Colors.grey.shade600, // ✅ Gris si está bloqueado
                                width: 4,
                              ),
                              color: isUnlocked ? colors.surface : Colors.grey.shade800, // ✅ Fondo gris si está bloqueado
                              // ✅ Añadir sombra interna para efecto de "hundido" cuando está bloqueado
                              boxShadow: !isUnlocked ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    animatedImg,
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        achievement.nombre.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: isUnlocked ? colors.onSurface : Colors.grey.shade400, // ✅ Gris si está bloqueado
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Icon(
                                      isUnlocked ? Icons.star : Icons.lock_outline,
                                      color: isUnlocked ? borderColor : Colors.grey.shade500, // ✅ Gris si está bloqueado
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
                                              color: isUnlocked ? colors.onSurfaceVariant : Colors.grey.shade400, // ✅ Gris si está bloqueado
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            achievement.descripcion,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isUnlocked ? colors.onSurfaceVariant : Colors.grey.shade400, // ✅ Gris si está bloqueado
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                                // ✅ Overlay de oscurecimiento cuando está bloqueado
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        color: Colors.black.withOpacity(0.3), // Overlay oscuro
                                      ),
                                    ),
                                  ),
                                // ✅ Candado grande en el centro cuando está bloqueado
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          size: 60,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
            ),
          ),
        ),
      ),
    );
  }
}