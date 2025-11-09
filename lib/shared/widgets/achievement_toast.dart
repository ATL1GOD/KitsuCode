import 'package:flutter/material.dart';

// Este es solo el WIDGET de la UI.
// El paquete 'overlay_support' se encargará de animarlo para que 
// aparezca y desaparezca.

class AchievementToast extends StatelessWidget {
  final String nombreLogro;
  final String iconUrl;

  const AchievementToast({
    super.key,
    required this.nombreLogro,
    required this.iconUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Usamos SafeArea para que la notificación no se encime
    // con la barra de estado/notch del teléfono.
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          // Márgenes para que no ocupe toda la pantalla
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Un color oscuro de tu tema (¡puedes cambiarlo!)
            color: colors.surfaceVariant, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primary.withOpacity(0.5), // Borde con tu color primario
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.2), // Sombra suave
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            children: [
              // --- El Icono del Logro ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  iconUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  // Un placeholder por si la imagen tarda o falla en cargar
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: colors.onSurface.withOpacity(0.1),
                      child: Icon(Icons.shield, color: colors.primary),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // --- El Texto ---
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¡Logro Desbloqueado!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary, // Color Kitsu
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nombreLogro,
                      style: TextStyle(
                        color: colors.onSurface, // Texto normal
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}