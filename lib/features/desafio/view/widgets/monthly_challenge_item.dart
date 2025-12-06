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
    final backgroundColor = isCompleted
        ? Colors.green.withAlpha(38)
        : Colors.black.withAlpha(51);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted
              ? null
              : () {
                  ref.read(navigationReturnPathProvider.notifier).state =
                      '/desafiomensual';
                  context.push('/reto/${desafio.idReto}/${desafio.nivelId}');
                },
          borderRadius: BorderRadius.circular(16),
          splashColor: parentColor.withAlpha(77),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted
                    ? Colors.greenAccent.withAlpha(128)
                    : Colors.white.withAlpha(26),
                width: 1.5,
              ),
              boxShadow: isCompleted
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : Colors.white.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.white
                          : parentColor.withAlpha(128),
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

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withAlpha(51)
                              : parentColor.withAlpha(51),
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
                              ? Colors.white.withAlpha(153)
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
                          color: Colors.black.withAlpha(51),
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
