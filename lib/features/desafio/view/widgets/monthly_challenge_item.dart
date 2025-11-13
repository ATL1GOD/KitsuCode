// features/desafio/presentation/widgets/monthly_challenge_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/core/providers/app_provider.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart'; // Modelos

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
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: Color.lerp(parentColor, Colors.black, 0.3),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.code,
          color: isCompleted ? Colors.green.shade300 : Colors.white,
        ),
        title: Text(
          desafio.titulo,
          style: TextStyle(
            color: isCompleted ? Colors.white70 : Colors.white,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white70,
          ),
        ),
        subtitle: Text('', style: const TextStyle(color: Colors.white70)),
        trailing: isCompleted
            ? const Icon(Icons.check, color: Colors.greenAccent)
            : const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
        onTap: isCompleted
            ? null
            : () {
                ref.read(navigationReturnPathProvider.notifier).state =
                    '/desafiomensual';
                context.push('/reto/${desafio.idReto}/${desafio.nivelId}');
              },
      ),
    );
  }
}
