// lib/features/competences/view/widgets/ranking_tile.dart

import 'package:flutter/material.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
// Importamos el modelo creado en el paso anterior

class RankingTile extends StatelessWidget {
  final RankingModel user;
  final bool isTop3;
  final bool isCurrentUser;
  final ColorScheme colors;

  const RankingTile({
    super.key,
    required this.user, 
    required this.isTop3, 
    required this.isCurrentUser, 
    required this.colors
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determinar color de fondo para destacar Top 3 y Usuario Actual
    Color tileColor = colors.surfaceContainerLow;
    if (user.position == 1) {
        tileColor = Colors.amber.shade100;
    } else if (user.position == 2) {
        tileColor = Colors.grey.shade300;
    } else if (user.position == 3) {
        tileColor = Colors.brown.shade200;
    } 
    
    if (isCurrentUser) {
        //
        tileColor = colors.secondaryFixed.withOpacity(0.9);
    }
    
    // 2. Icono y color de la medalla
    Color medalColor = isTop3 ? colors.secondary : colors.onSurfaceVariant;
    if (user.position == 1) {
        medalColor = Colors.amber.shade700;
    } else if (user.position == 2) {
        medalColor = Colors.grey.shade600;
    } else if (user.position == 3) {
        medalColor = Colors.brown.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: tileColor,
      elevation: isCurrentUser ? 8 : (isTop3 ? 4 : 1),
      shadowColor: isCurrentUser ? colors.secondary : colors.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isCurrentUser ? colors.secondary : Colors.transparent, //
          width: isCurrentUser ? 2.0 : 0.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Posición (Punto 4 de C.U-03-02)
            SizedBox(
              width: 30, 
              child: Text(
                '#${user.position}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isTop3 ? medalColor : colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(user.avatarUrl),
              backgroundColor: colors.surfaceVariant,
            ),
          ],
        ),
        
        // Nombre de Perfil y Username
        title: Text(
          user.profileName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: colors.primary), //
        ),
        
        // Puntaje y Rango (Punto 4 de C.U-03-02)
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Puntaje
            Text(
              '${user.totalScore} Pts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            // Rango
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: medalColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  user.rank,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: medalColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}