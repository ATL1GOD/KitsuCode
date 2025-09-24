import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart';

class AuthBackground extends StatefulWidget {
  final bool isMobile;
  final Widget child;

  const AuthBackground({
    super.key,
    required this.isMobile,
    required this.child,
  });

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with TickerProviderStateMixin {
  // Lista de las imágenes que se usarán para las burbujas
  final List<String> _particleImages = [
    'assets/images/burbuja_c.png',
    'assets/images/burbuja_java.png',
    'assets/images/burbuja_python.png',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(51),
                  colorScheme.tertiary.withAlpha(51),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          ..._particleImages.map(
            (imagePath) => AnimatedBackground(
              vsync: this,
              behaviour: RandomParticleBehaviour(
                // Opciones para controlar la física y apariencia de las partículas
                options: ParticleOptions(
                  spawnMaxRadius: 90,
                  spawnMinRadius: 80,
                  spawnMinSpeed: 40.0,
                  spawnMaxSpeed: 45.0,
                  particleCount: 5,
                  minOpacity: 0.3,
                  spawnOpacity: 1,
                  image: Image.asset(imagePath),
                ),
              ),
              child: Container(),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/fox_login.png',
                        height: widget.isMobile ? 340 : 420,
                      ),
                      const SizedBox(height: 1),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
