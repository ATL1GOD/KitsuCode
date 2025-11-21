import 'package:flutter/material.dart';
import 'package:kitsucode/features/home/view/widgets/buttons_home.dart';
import 'package:kitsucode/features/home/model/home_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/shared/appbar/app_bar_provider.dart';
import 'package:kitsucode/features/home/view/widgets/animated_level_node.dart';
import 'package:kitsucode/shared/snackbar/snackbar.dart';
import 'package:kitsucode/core/providers/audio_provider.dart';
import 'package:kitsucode/features/challenge/provider/challenge_music_provider.dart'; // 🔥 NUEVO

class Section extends ConsumerWidget {
  final SectionData data;

  const Section({super.key, required this.data});

  void _navegarAReto(BuildContext context, WidgetRef ref, LevelData level) {
    // --- LÓGICA DE BLOQUEO DE NIVEL ---
    if (level.isLocked) {
      showWarningSnackbar(
        context,
        '¡Nivel Bloqueado!',
        'Completa el reto anterior para desbloquear este nivel.',
      );
      return;
    }

    // 1. Si no hay retoId, es una lección
    if (level.retoId == null) {
      debugPrint(
        "Lección ${level.nivel} presionada (ID: ${level.idNivel}). Sin reto.",
      );
      return;
    }

    // 2. Lógica de bloqueo de vidas
    final appBarState = ref.read(appBarProvider);

    if (appBarState.lives <= 0) {
      showErrorSnackbar(
        context,
        '¡Sin Vidas!',
        '¡Oh no! Te has quedado sin vidas. Vuelve mañana.',
      );
      return;
    }

    // 🔥 3. PAUSAR LA MÚSICA ANTES DE NAVEGAR
    pauseMusicForChallenge(ref);
    ref.read(audioControllerProvider).stopMusic();

    // 4. Navegar al reto
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

        SizedBox(
          height: stackHeight,
          child: Stack(
            children: data.levels.asMap().entries.map((entry) {
              int i = entry.key;
              LevelData level = entry.value;

              final Widget levelNodeWidget = ReliefSectionButton(
                onPressed: () {
                  ref.read(audioControllerProvider).playClick();
                  _navegarAReto(context, ref, level);
                },
                baseColor: data.color,
                reliefColor: data.colorOscuro,
                svgAsset: level.iconAsset,
                size: 56.0,
                reliefThickness: 6.0,
                isLocked: level.isLocked,
                lockColor: Colors.grey.shade600,
              );

              return Positioned(
                key: ValueKey('level_${level.idNivel}'),
                top: (i * 96.0) + 40.0,
                left: getLeft(i),
                right: getRight(i),
                child: AnimatedLevelNode(
                  key: ValueKey(level.idNivel),
                  levelId: level.idNivel,
                  child: levelNodeWidget,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double getLeft(int indice) {
    const margin = 72.0;
    int pos = indice % 9;
    if (pos == 1) return margin;
    if (pos == 2) return margin * 2;
    if (pos == 3) return margin;
    return 0.0;
  }

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