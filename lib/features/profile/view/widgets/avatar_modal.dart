import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // Para la clase Color
import 'package:flutter/foundation.dart' show kDebugMode;

// --- Función de ayuda para el color ---
Color _safeParseColor(String colorString) {
  try {
    return Color(int.parse(colorString));
  } catch (e) {
    if (kDebugMode) debugPrint('Error al parsear color "$colorString": $e');
    return const Color(0xFF9E9E9E); // Gris
  }
}
// --- Fin de la función de ayuda ---


class AvatarModal extends StatelessWidget {
  final AvatarModel avatar;

  const AvatarModal({
    super.key,
    required this.avatar,
  });

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
                  backgroundColor: Colors.transparent, // Fondo transparente
                  body: _ModalContent(
                    avatar: avatar,
                  ),
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
      body: _ModalContent(
        avatar: avatar,
      ),
    );
  }
}

class _ModalContent extends StatelessWidget {
  final AvatarModel avatar;

  const _ModalContent({
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUnlocked = avatar.desbloqueado;

    // ✅ ¡LA MAGIA DE TU IDEA!
    // El color, el aura y la imagen siempre están a color.
    final Color borderColor = _safeParseColor(avatar.colorPrimario);
    final String tipo = avatar.tipo;
    final String tipoText = tipo.substring(0, 1).toUpperCase() + tipo.substring(1);
    final lockedColor = colors.onSurfaceVariant.withOpacity(0.5);

    // --- Lógica de Imagen (SIEMPRE A COLOR) ---
    Widget img = Image.asset(
        avatar.assetPath,
        height: 200,
        width: double.infinity,
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

    // --- Aura (SIEMPRE A COLOR) ---
    final aura = Icon(
            Icons.auto_awesome,
            size: 120,
            color: borderColor.withOpacity(0.5), // Siempre usa el color primario
          )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 800.ms,
        );
    // --- Fin Lógica ---

    // --- Lógica de Texto (depende de si está bloqueado) ---
    final String descriptionTitle = isUnlocked
        ? "¡Avatar desbloqueado!"
        : "Para desbloquear este avatar necesitas:";
    
    final String descriptionBody = avatar.requisitoDescripcion ?? avatar.descripcion ?? "Sigue jugando para descubrirlo.";


    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withOpacity(0.7), // Fondo "dim"
        child: GestureDetector(
          onTap: () {}, // Evita cerrar al tocar el modal
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  aura, // Aura de color
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: colors.surface, // Fondo siempre claro/oscuro
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withOpacity(0.7), // Sombra siempre de color
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
                                style: Theme.of(context).textTheme.titleMedium
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // --- Círculo de ID (siempre a color) ---
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: borderColor.withOpacity(0.2),
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
                                  // --- Tag de Tipo/Rareza (siempre a color) ---
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: borderColor.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tipoText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: colors.onPrimary, // Asumimos color claro
                                      ),
                                    ),
                                  ),
                                  // --- Texto de Estado (CAMBIA) ---
                                  Flexible(
                                    child: Text(
                                      isUnlocked ? "¡OBTENIDO!" : "BLOQUEADO",
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? const Color(0xFF00FF00) // Verde
                                            : lockedColor, // Gris
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
                        // --- Contenedor de la Imagen ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: borderColor, // Borde siempre de color
                                width: 4,
                              ),
                              color: colors.surface,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    animatedImg, // Imagen siempre a color
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
                                          color: colors.onSurface, // Siempre a color
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // --- Icono de Estado (CAMBIA) ---
                                    Icon(
                                      isUnlocked
                                          ? Icons.check_circle
                                          : Icons.lock_outline,
                                      color: isUnlocked
                                          ? borderColor
                                          : Colors.grey.shade500, // Gris si está bloqueado
                                      size: 24,
                                    ),
                                    const SizedBox(height: 10),
                                    // --- Descripción de Requisito ---
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            descriptionTitle, // Título dinámico
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSurfaceVariant
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            descriptionBody, // Cuerpo dinámico
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                                // --- Overlay de Candado (SOLO SI ESTÁ BLOQUEADO) ---
                                if (!isUnlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
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
                        // --- Botón de Cerrar ---
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