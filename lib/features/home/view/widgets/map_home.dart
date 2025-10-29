import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart';
import 'package:go_router/go_router.dart'; // Importar GoRouter

class Section extends StatelessWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
            const SizedBox(width: 16),
            Text(
              data.titulo,
              style: const TextStyle(
                color: Color(0xFF52656D),
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Divider(color: Color(0xFF2D3D41))),
          ],
        ),
        const SizedBox(height: 24.0),
        // AHORA GENERAMOS LOS BOTONES DINÁMICAMENTE BASADOS EN data.levels
        // Los niveles vienen ordenados de la DB
        ...data.levels.asMap().entries.map((entry) {
          final i = entry.key; // Índice
          final level = entry.value; // Objeto LevelData

          // Usa retoId para determinar si es un Reto/Quiz o una Lección normal
          final bool isQuiz = level.retoId != null;

          return Container(
            margin: EdgeInsets.only(
              // El último nivel no tiene margen inferior
              bottom: i != data.levels.length - 1 ? 24.0 : 0,
              // Usa la lógica de posición existente
              left: getLeft(i),
              right: getRight(i),
            ),
            child: ReliefSectionButton(
              onPressed: () {
                if (isQuiz) {
                  // CORRECCIÓN: Usar GoRouter para navegar
                  // Se usa 'push' porque la página del Quiz no tiene navbar y no es parte del Shell.
                  context.push('/quiz-loader/${level.retoId}');
                } else {
                  // Lógica para una lección normal (sin reto asociado)
                  print(
                    "Lección ${level.nivel} presionado (ID: ${level.idNivel})",
                  );
                }
              },
              baseColor: data.color,
              reliefColor: data.colorOscuro,
              // Usar el asset del ícono cargado de la DB
              svgAsset: level.iconAsset,
              size: 56.0,
              reliefThickness: 6.0,
            ),
          );
        }).toList(),
      ],
    );
  }

  // Lógica de posicionamiento (Sin cambios)
  double getLeft(int indice) {
    const margin = 72.0;
    int pos = indice % 9;
    if (pos == 1) return margin;
    if (pos == 2) return margin * 2;
    if (pos == 3) return margin;
    return 0.0;
  }

  // Lógica de posicionamiento (Sin cambios)
  double getRight(int indice) {
    const margin = 72.0;
    int pos = indice % 9;
    if (pos == 5) return margin;
    if (pos == 6) return margin * 2;
    if (pos == 7) return margin;
    return 0.0;
  }
}
