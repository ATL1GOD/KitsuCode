import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';

Color _safeParseColor(String colorString) {
  try {
    return Color(int.parse(colorString));
  } catch (e) {
    debugPrint('Error al parsear color "$colorString": $e');
    return const Color(0xFF9E9E9E);
  }
}

class AvatarModal extends StatelessWidget {
  final AvatarModel avatar;

  const AvatarModal({super.key, required this.avatar});

  static Future<void> show(
    BuildContext context, {
    required AvatarModel avatar,
  }) async {
    final theme = Theme.of(context);

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Theme(
            data: theme,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: _ModalContent(avatar: avatar),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _ModalContent(avatar: avatar),
    );
  }
}

class _ModalContent extends StatelessWidget {
  final AvatarModel avatar;

  const _ModalContent({required this.avatar});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUnlocked = avatar.desbloqueado;

    final Color borderColor = _safeParseColor(avatar.colorPrimario);
    final String tipo = avatar.tipo;
    final String tipoText =
        tipo.substring(0, 1).toUpperCase() + tipo.substring(1);
    final lockedColor = colors.onSurfaceVariant.withAlpha(128);

    Widget img = OptimizedImage(
      imagePath: avatar.assetPath,
      height: 200,
      width: 320,
      fit: BoxFit.cover,
    );

    final animatedImg = ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      child: img
          .animate()
          .scale(
            begin: const Offset(1.3, 1.3),
            end: const Offset(1.0, 1.0),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .then()
          .shake(duration: 600.ms, hz: 3, offset: const Offset(3, 3))
          .then()
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 250.ms,
            curve: Curves.easeOut,
          ),
    );

    final aura =
        Icon(Icons.auto_awesome, size: 120, color: borderColor.withAlpha(128))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
            );

    final String descriptionTitle = isUnlocked
        ? "¡Avatar desbloqueado!"
        : "Para desbloquear este avatar necesitas:";

    final String descriptionBody =
        avatar.requisitoDescripcion ?? avatar.descripcion;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withAlpha(179),
        child: GestureDetector(
          onTap: () {},
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
                      color: colors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withAlpha(179),
                          blurRadius: 30,
                          spreadRadius: 5,
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
                              Text(
                                "Avatar",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: borderColor.withAlpha(51),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${avatar.id}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: borderColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: borderColor.withAlpha(204),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tipoText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: colors.onPrimary,
                                      ),
                                    ),
                                  ),

                                  Flexible(
                                    child: Text(
                                      isUnlocked ? "¡OBTENIDO!" : "BLOQUEADO",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? const Color(0xFF00FF00)
                                            : lockedColor,
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
                              border: Border.all(color: borderColor, width: 4),
                              color: colors.surface,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    animatedImg,
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Text(
                                        avatar.nombre.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: colors.onSurface,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    Icon(
                                      isUnlocked
                                          ? Icons.check_circle
                                          : Icons.lock_outline,
                                      color: isUnlocked
                                          ? borderColor
                                          : Colors.grey.shade500,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 10),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            descriptionTitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            descriptionBody,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),

                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        color: Colors.black.withAlpha(77),
                                      ),
                                    ),
                                  ),
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(179),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Cerrar",
                              style: TextStyle(color: colors.onPrimary),
                            ),
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
