import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitsucode/features/profile/model/challenge_history_model.dart';

class ChallengeHistoryTile extends StatelessWidget {
  final ChallengeHistoryModel item;

  const ChallengeHistoryTile({super.key, required this.item});

  IconData _getIconForDinamica(String? dinamica) {
    switch (dinamica?.toLowerCase()) {
      case 'bloques':
        return Icons.extension_outlined;
      case 'relacion':
        return Icons.view_column_outlined;
      case 'codigo':
        return Icons.code_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'evento':
        return Icons.star_border_purple500_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat formatter = DateFormat('dd/MM/yyyy - hh:mm a');

    final bool isSuccess = item.resultado.toLowerCase() == 'completado';
    final Color auraColor = (isSuccess ? Colors.green : Colors.red).withOpacity(
      0.7,
    );
    final Color cardColor = isSuccess
        ? colorScheme.surface.withAlpha(230)
        : colorScheme.errorContainer.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: auraColor, blurRadius: 10, spreadRadius: 1),
        ],
        border: Border.all(color: auraColor.withAlpha(204), width: 1.5),
      ),
      child: ListTile(
        leading: Icon(
          _getIconForDinamica(item.dinamicaNombre),
          color: colorScheme.primary,
          size: 30,
        ),
        title: Text(
          item.challengeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${item.sectionTitle}  •  ${formatter.format(item.completedAt.toLocal())}',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.emoji_events_outlined : Icons.cancel_outlined,
              color: isSuccess ? Colors.amber[700] : Colors.red[700],
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              isSuccess ? '+${item.xpGained}' : '0',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
