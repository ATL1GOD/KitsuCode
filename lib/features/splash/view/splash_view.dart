import 'package:flutter/material.dart';

// ¡Ya NO se necesita importar 'app_colors.dart'!

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ¡LA SOLUCIÓN! ---
    // Obtenemos los colores del Tema del contexto,
    // igual que en ProfileView y SettingsView.
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Usamos el color de fondo más oscuro del tema
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // 1. El fondo de "resplandor" naranja (estático)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                // Centrado arriba
                center: const Alignment(0, -0.8),
                radius: 0.9,
                colors: [
                  // Usamos el color 'secondary' (acento/naranja) del tema
                  colorScheme.secondary.withAlpha(77), // (0.3 * 255)
                  
                  // Se difumina al color de fondo del tema
                  colorScheme.surfaceContainerLowest.withAlpha(0),
                ],
              ),
            ),
          ),

          // 2. El contenido centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // La imagen del zorro que pediste
                Image.asset(
                  'assets/images/auth/fox_login.png',
                  width: 250, // Un tamaño razonable
                ),
                const SizedBox(height: 48),

                // Indicador de carga
                CircularProgressIndicator(
                  // Usamos el color 'secondary' (acento/naranja) del tema
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                ),
                const SizedBox(height: 24),
                Text(
                  'Cargando...',
                  style: TextStyle(
                    // Usamos el color de texto 'sobre' el fondo del tema
                    color: colorScheme.onSurface.withAlpha(204), // (0.8 * 255)
                    fontSize: 16,
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