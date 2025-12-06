import 'package:flutter/material.dart';
import 'package:kitsucode/features/competences/model/ranking_model.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/shared/optimized_image/optimizador_imagenes.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';

class RankingTile extends StatelessWidget {
  final RankingModel user;
  final bool isCurrentUser;
  final ColorScheme colors;
  final List<AvatarModel>? avatarsList;
  final VoidCallback? onModalOpen;
  final VoidCallback? onModalClose;

  const RankingTile({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.colors,
    this.avatarsList,
    this.onModalOpen,
    this.onModalClose,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color rankColor;
    switch (user.rank.toLowerCase()) {
      case 'diamante':
        rankColor = Colors.blue.shade300;
        break;
      case 'oro':
        rankColor = Colors.amber.shade600;
        break;
      case 'plata':
        rankColor = Colors.grey.shade400;
        break;
      default:
        rankColor = Colors.brown.shade400;
    }

    final avatarPath = getAvatarAssetPathById(
      user.idAvatarSeleccionado,
      avatarsList,
    );

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        clipBehavior: Clip.antiAlias,
        color: isCurrentUser
            ? colors.secondaryContainer.withAlpha(102)
            : colors.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isCurrentUser ? colors.secondary : colors.outlineVariant,
            width: isCurrentUser ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (isCurrentUser) return;
            onModalOpen?.call();
            await showDialog(
              context: context,
              builder: (ctx) =>
                  UserProfileModal(userId: user.userId, rank: user.rank),
            );
            onModalClose?.call();
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 35,
                  child: Text(
                    '#${user.position}',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: avatarPath.isEmpty
                          ? const SizedBox.shrink()
                          : OptimizedImage(
                              imagePath: avatarPath,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              enableCache: true,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              user.profileName,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '@${user.username}',
              style: textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${user.totalScore} Pts',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: rankColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      user.rank,
                      style: textTheme.bodySmall?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
