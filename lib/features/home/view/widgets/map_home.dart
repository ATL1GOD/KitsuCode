// [COMIENZO DEL ARCHIVO map_home.dart]
import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';

class Section extends ConsumerWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  void _navegarAReto(BuildContext context, WidgetRef ref, LevelData level) {
    // --- LÓGICA DE BLOQUEO DE NIVEL ---
    if (level.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Nivel bloqueado! Completa el reto anterior primero.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return; // Bloquea la navegación
    }
    // --- FIN LÓGICA DE BLOQUEO DE NIVEL ---

    // 1. Si no hay retoId, es una lección (sin cambios)
    if (level.retoId == null) {
      debugPrint(
        "Lección ${level.nivel} presionada (ID: ${level.idNivel}). Sin reto.",
      );
      // context.push('/leccion/${level.idNivel}');
      return;
    }

    // 2. Lógica de bloqueo de vidas (sin cambios)
    final appBarState = ref.read(appBarProvider);

    if (appBarState.lives <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oh no! Te has quedado sin vidas. Vuelve mañana.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return; // Bloquea la navegación
    }
    // --- FIN DE LA LÓGICA DE BLOQUEO DE VIDAS ---

    // 3. Si tiene vidas Y está desbloqueado, navegamos
    final int retoId = level.retoId!;
    final int nivelId = level.idNivel;
    context.push('/reto/$retoId/$nivelId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double buttonHeight = 62.0;
    final double stackHeight = data.levels.isEmpty
        ? 0.0
        : ((data.levels.length - 1) * 96.0 + 40.0) + buttonHeight;

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

        // --- STACK DE BOTONES ---
        SizedBox(
          height: stackHeight,
          child: Stack(
            children: data.levels.asMap().entries.map((entry) {
              int i = entry.key;
              LevelData level = entry.value;

              return Positioned(
                top: (i * 96.0) + 40.0,
                left: getLeft(i),
                right: getRight(i),
                child: ReliefSectionButton(
                  onPressed: () {
                    // Llamamos a la función con el ref
                    _navegarAReto(context, ref, level);
                  },
                  baseColor: data.color,
                  reliefColor: data.colorOscuro,
                  svgAsset: level.iconAsset,
                  size: 56.0,
                  reliefThickness: 6.0,
                  // --- Usamos el estado de bloqueo del modelo ---
                  isLocked: level.isLocked,
                  lockColor: Colors.grey.shade600,
                  // --- Fin del estado de bloqueo ---
                ),
              );
            }).toList(),
          ),
        ),
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
// [FIN DEL ARCHIVO map_home.dart]