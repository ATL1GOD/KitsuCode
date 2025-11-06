// [COMIENZO DEL ARCHIVO map_home.dart]
import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:go_router/go_router.dart'; // Importar GoRouter

// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';


// --- ¡CAMBIO: A ConsumerWidget! ---
class Section extends ConsumerWidget { 
  final SectionData data;

  const Section({super.key, required this.data});

  // --- ¡FUNCIÓN DE NAVEGACIÓN MODIFICADA! ---
  // (Ahora acepta 'WidgetRef ref')
  void _navegarAReto(BuildContext context, WidgetRef ref, LevelData level) {
    // 1. Si no hay retoId, es una lección (sin cambios)
    if (level.retoId == null) {
      debugPrint( // <-- Usamos debugPrint
        "Lección ${level.nivel} presionada (ID: ${level.idNivel}). Sin reto.",
      );
      // context.push('/leccion/${level.idNivel}');
      return;
    }
    
    // --- ¡NUEVA LÓGICA DE BLOQUEO DE VIDAS! ---
    // 2. Leemos el estado actual del AppBar
    final appBarState = ref.read(appBarProvider);
    
    // 3. Comprobamos las vidas
    if (appBarState.lives <= 0) {
      // Si no tiene vidas, mostramos un SnackBar y NO navegamos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Oh no! Te has quedado sin vidas. Vuelve mañana.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return; // <-- Bloquea la navegación
    }
    // --- FIN DE LA LÓGICA DE BLOQUEO ---

    // 4. Si tiene vidas, navegamos (tu lógica original)
    final int retoId = level.retoId!;
    debugPrint("Navegando al distribuidor de retos con ID: $retoId");
    context.push('/reto/$retoId');
  }
  // --- FIN NUEVA FUNCIÓN ---

  @override
  // --- ¡CAMBIO: Añadido 'WidgetRef ref'! ---
  Widget build(BuildContext context, WidgetRef ref) { 
    // --- CÁLCULO DE ALTURA DEL STACK (Sin cambios) ---
    const double buttonHeight = 62.0;
    final double stackHeight = data.levels.isEmpty
        ? 0.0
        : ((data.levels.length - 1) * 96.0 + 40.0) + buttonHeight;
    // --- FIN CÁLCULO DE ALTURA ---

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

        // --- STACK DE BOTONES (Sin cambios) ---
        SizedBox(
          height: stackHeight,
          child: Stack(
            children: data.levels.asMap().entries.map((entry) {
              int i = entry.key; // El índice (0, 1, 2...)
              LevelData level = entry.value;

              return Positioned(
                top: (i * 96.0) + 40.0,
                left: getLeft(i),
                right: getRight(i),
                child: ReliefSectionButton(
                  onPressed: () {
                    // --- ¡CAMBIO: Pasamos el 'ref'! ---
                    _navegarAReto(context, ref, level);
                  },
                  baseColor: data.color,
                  reliefColor: data.colorOscuro,
                  svgAsset: level.iconAsset,
                  size: 56.0,
                  reliefThickness: 6.0,
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