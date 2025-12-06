import 'package:flutter/material.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

class StaticSettingsBackground extends ConsumerWidget {
  final UserProfileModel profile;
  final ColorScheme colors;

  const StaticSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];
    final int avatarId = profile.idAvatarSeleccionado;

    final dynamicColor = avatarsList.isNotEmpty
        ? getAvatarColorById(avatarId, avatarsList)
        : AllStatsView.getHeaderColor(profile, colors);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dynamicColor.withAlpha(100), colors.surfaceContainerLowest],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
