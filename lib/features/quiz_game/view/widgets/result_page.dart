import 'package:flutter/material.dart';
import 'package:kitsucode/core/utils/app_colors.dart'; // Asegúrate que la ruta sea correcta

class QuizResultPage extends StatefulWidget {
  final int marks;
  final int totalQuestions;
  final int durationInSeconds;

  const QuizResultPage({
    Key? key,
    required this.marks,
    required this.totalQuestions,
    required this.durationInSeconds,
  }) : super(key: key);

  @override
  _QuizResultPageState createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  final List<String> images = [
    "assets/images/success.png",
    "assets/images/good.png",
    "assets/images/bad.png",
  ];

  late String image;
  late int percentage;
  late String formattedTime;

  @override
  void initState() {
    super.initState();
    // Lógica para determinar la imagen basada en el puntaje
    final double scoreRatio = widget.marks / (widget.totalQuestions * 5);
    if (scoreRatio < 0.5) {
      image = images[2]; // bad
    } else if (scoreRatio < 0.8) {
      image = images[1]; // good
    } else {
      image = images[0]; // success
    }

    // Calcular porcentaje de aciertos
    percentage = (scoreRatio * 100).round();

    // Formatear el tiempo
    final int minutes = widget.durationInSeconds ~/ 60;
    final int seconds = widget.durationInSeconds % 60;
    formattedTime =
        "${minutes.toString()}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final colorScheme = (brightness == Brightness.dark)
        ? pythonDarkColorScheme
        : pythonLightColorScheme;

    return Theme(
      data: ThemeData.from(colorScheme: colorScheme, useMaterial3: true),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                Image.asset(image, height: 200, fit: BoxFit.contain),
                const SizedBox(height: 24),
                Text(
                  '¡Completaste la práctica!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                // Fila de estadísticas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCard(
                      label: 'EXP TOTALES',
                      value: widget.marks.toString(),
                      icon: Icons.star_rounded,
                      colorScheme: colorScheme,
                    ),
                    _StatCard(
                      label: 'BIEN',
                      value: '$percentage%',
                      icon: Icons.check_circle_rounded,
                      colorScheme: colorScheme,
                    ),
                    _StatCard(
                      label: 'ÁGIL',
                      value: formattedTime,
                      icon: Icons.timer_rounded,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const Spacer(),
                // Botón inferior
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable para las tarjetas de estadísticas
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: colorScheme.outline, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
