// lib/shared/widgets/kitsu_action_modal.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// Muestra un modal sheet de acción personalizado (en lugar de un AlertDialog).
Future<T?> showKitsuActionModal<T>({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color dynamicColor,
  Color? iconColor,
  Widget? customContent,
  required List<Widget> actions,
}) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  
  // El color del ícono usará el dynamicColor si no se especifica uno
  final Color finalIconColor = iconColor ?? dynamicColor;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24.0).copyWith(bottom: 16.0),
          // --- ¡DECORACIÓN DE AURA USANDO DYNAMIC COLOR! ---
          decoration: BoxDecoration(
            color: colors.surfaceContainer, // <-- 1. ¡OPACIDAD ELIMINADA!
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
            border: Border.all(color: dynamicColor.withOpacity(.6)), // Borde de aura
            boxShadow: [
              BoxShadow(
                color: dynamicColor.withOpacity(.25), // Sombra de aura
                blurRadius: 12,
                offset: const Offset(0, 5),
              )
            ],
          ),
          // --- FIN DE LA DECORACIÓN ---
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. "Drag Handle"
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Icono
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Icon(icon, color: finalIconColor, size: 48), // Usa el color final
              ),
              const SizedBox(height: 16),

              // 3. Título
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 4. Mensaje
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Contenido Personalizado
              if (customContent != null)
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: customContent,
                  ),
                ),

              // 6. Botones
              FadeInDown(
                delay: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}