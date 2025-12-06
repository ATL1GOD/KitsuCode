import 'package:flutter/material.dart';
import 'package:kitsucode/features/desafio/provider/desafio_provider.dart';
import 'monthly_challenge_item.dart';

class SpecialEventExpandableContent extends StatelessWidget {
  final List<RetoIndividual> desafiosMensuales;
  final Set<int> completedRetoIds;
  final Color parentColor;

  const SpecialEventExpandableContent({
    super.key,
    required this.desafiosMensuales,
    required this.completedRetoIds,
    required this.parentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RETOS INDIVIDUALES DEL EVENTO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (desafiosMensuales.isEmpty)
            const Text(
              'No hay retos definidos para este evento.',
              style: TextStyle(color: Colors.white70),
            )
          else
            ...desafiosMensuales.map(
              (desafio) => MonthlyChallengeItem(
                desafio: desafio,
                parentColor: parentColor,
                isCompleted: completedRetoIds.contains(desafio.idReto),
              ),
            ),
        ],
      ),
    );
  }
}
