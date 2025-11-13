// lib/features/profile/view/widgets/challenge_history_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitsucode/features/profile/model/challenge_history_model.dart';

class ChallengeHistoryTile extends StatelessWidget {
  final ChallengeHistoryModel item;

  const ChallengeHistoryTile({super.key, required this.item});

  // --- ¡FUNCIÓN HELPER ACTUALIZADA! ---
  // Ahora decide el icono basado en el NOMBRE de la dinámica
  IconData _getIconForDinamica(String? dinamica) {
    // Usamos tu mapeo
    switch (dinamica?.toLowerCase()) {
      case 'bloques': // Puzzle
        return Icons.extension_outlined;
      case 'relacion': // Relación de Columnas
        return Icons.view_column_outlined;
      case 'codigo': // Código escrito
        return Icons.code_outlined;
      case 'quiz': // Preguntas
        return Icons.quiz_outlined;
      case 'evento':
        return Icons.star_border_purple500_outlined;
      default:
        return Icons.help_outline; // Icono por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final DateFormat formatter = DateFormat('dd/MM/yyyy - hh:mm a');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface.withOpacity(0.9),
      child: ListTile(
        // --- CAMBIO DE ICONO LEADING ---
        leading: Icon(
          _getIconForDinamica(item.dinamicaNombre), // <-- USA LA NUEVA FUNCIÓN
          color: colorScheme.primary,
          size: 30,
        ),

        // --- TÍTULO (SIN CAMBIOS) ---
        title: Text(
          item.challengeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // --- SUBTÍTULO (SIN CAMBIOS) ---
        // Sigue mostrando la sección (Pilas, Colas) y la fecha
        subtitle: Text(
          // Añade ".toLocal()" justo después de "item.completedAt"
          '${item.sectionTitle}  •  ${formatter.format(item.completedAt.toLocal())}',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),

        // --- TRAILING (SIN CAMBIOS) ---
        // Mantenemos el icono de trofeo y la XP
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber[700],
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '+${item.xpGained}',
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