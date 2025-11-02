import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
// import 'package:kitsucode/features/quiz_game/view/quiz_loader.dart'; // Ya no se importa aquí
import 'package:go_router/go_router.dart'; // Importar GoRouter

class Section extends StatelessWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  // --- NUEVA FUNCIÓN DE NAVEGACIÓN ---
  void _navegarAReto(BuildContext context, LevelData level) {
    // Si no hay retoId o no hay nombre de dinámica, es una lección (o no hacer nada)
    if (level.retoId == null || level.dinamicaNombre == null) {
      print(
        "Lección ${level.nivel} presionada (ID: ${level.idNivel}). Sin reto.",
      );
      // Aquí podrías navegar a una pantalla de "lección" si quisieras
      // context.push('/leccion/${level.idNivel}');
      return;
    }

    final int retoId = level.retoId!;
    final String dinamica = level.dinamicaNombre!;

    print("Navegando a reto $retoId con dinámica $dinamica");

    // Usa un switch para decidir a qué ruta navegar
    switch (dinamica) {
      case 'Quiz':
        // Navega al cargador de Quiz (que ya tienes)
        context.push('/quiz-loader/$retoId');
        break;
      case 'Puzzle':
        // Navega a un *nuevo* cargador de Puzzle
        context.push('/puzzle-loader/$retoId');
        break;
      case 'Columnas':
        // Navega a un *nuevo* cargador de Columnas
        context.push('/columns-loader/$retoId');
        break;
      case 'Codigo':
        // Navega a un *nuevo* cargador de Código
        context.push('/code-loader/$retoId');
        break;
      default:
        print("Dinámica no reconocida: $dinamica");
        // Mostrar un error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Dinámica "$dinamica" no implementada.'),
          ),
        );
    }
  }
  // --- FIN NUEVA FUNCIÓN ---

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          // ... (Widget del título de la sección, sin cambios) ...
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

        // Generar botones dinámicamente
        ...data.levels.asMap().entries.map((entry) {
          int i = entry.key; // El índice (0, 1, 2...)
          LevelData level = entry.value;

          // bool isQuiz = level.retoId != null; // Lógica antigua eliminada

          return Positioned(
            top: (i * 96.0) + 40.0,
            left: getLeft(i),
            right: getRight(i),
            child: ReliefSectionButton(
              onPressed: () {
                // --- LÓGICA MODIFICADA ---
                _navegarAReto(context, level);
                // --- FIN LÓGICA MODIFICADA ---
              },
              baseColor: data.color,
              reliefColor: data.colorOscuro,
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
    if (pos == 1) return 0.0;
    if (pos == 2) return 0.0;
    if (pos == 3) return margin;
    if (pos == 4) return margin * 2;
    if (pos == 5) return margin;
    if (pos == 6) return 0.0;
    if (pos == 7) return margin;
    if (pos == 8) return margin * 2;
    return 0.0;
  }
}
