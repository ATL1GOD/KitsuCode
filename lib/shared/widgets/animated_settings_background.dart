import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:kitsucode/features/profile/view/all_stats_view.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';

class AnimatedSettingsBackground extends ConsumerWidget {
  final UserProfileModel profile;
  final ColorScheme colors;
  final bool isKeyboardVisible;

  final int? avatarIdOverride;

  const AnimatedSettingsBackground({
    super.key,
    required this.profile,
    required this.colors,
    required this.isKeyboardVisible,
    this.avatarIdOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

    final int avatarId = avatarIdOverride ?? profile.idAvatarSeleccionado;

    final dynamicColor = avatarsList.isNotEmpty
        ? getAvatarColorById(avatarId, avatarsList)
        : AllStatsView.getHeaderColor(profile, colors);

    return RepaintBoundary(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dynamicColor.withAlpha((255 * 0.4).round()),
                  colors.surfaceContainerLowest,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),

          Visibility(
            visible: !isKeyboardVisible,
            maintainState: false,
            child: AnimatedOpacity(
              opacity: isKeyboardVisible ? 0.0 : 0.85,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.secondaryFixedDim.withAlpha((255 * 0.8).round()),
                  BlendMode.srcIn,
                ),
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: Lottie.asset(
                      'assets/animations/spring.json',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      repeat: true,
                      frameRate: FrameRate(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
