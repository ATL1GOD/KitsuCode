// features/desafio/presentation/widgets/monthly_challenge_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/providers/app_provider.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';

class MonthlyChallengeItem extends ConsumerWidget {
  final RetoIndividual desafio;
  final Color parentColor;
  final bool isCompleted;

  const MonthlyChallengeItem({
    super.key,
    required this.desafio,
    required this.parentColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Definimos colores base para el estado
    final backgroundColor = isCompleted
        ? Colors.green.withOpacity(0.15)
        : Colors.black.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted
              ? null // Si quieres que se pueda volver a ver, quita el null
              : () {
                  ref.read(navigationReturnPathProvider.notifier).state =
                      '/desafiomensual';
                  context.push('/reto/${desafio.idReto}/${desafio.nivelId}');
                },
          borderRadius: BorderRadius.circular(16),
          splashColor: parentColor.withOpacity(0.3),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // --- 1. Icono / Badge de Nivel ---
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.white
                          : parentColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.emoji_events_rounded
                          : Icons.star_rounded,
                      color: isCompleted ? Colors.white : parentColor,
                      size: 22,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // --- 2. Información del Reto ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge pequeña de "Nivel X"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.2)
                              : parentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "NIVEL ${desafio.nivelId}",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desafio.titulo,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // --- 3. Botón de Acción (Play / Check) ---
                if (isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 28,
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: parentColor,
                      size: 24,
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
