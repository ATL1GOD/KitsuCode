import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/competences/view/widgets/user_profile_modal.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/utils/avatar_helpers.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_achievements_section.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_header.dart';
import 'package:kitsucode/features/profile/view/widgets/profile_progress_section.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

import 'package:visibility_detector/visibility_detector.dart';

class ProfileView extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileView({super.key, this.userId});

  static Color getHeaderColor(
    UserProfileModel userProfile,
    ColorScheme colors,
  ) {
    return getAvatarColorById(userProfile.idAvatarSeleccionado);
  }

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _lottieController;

  bool _isTabVisible = true;
  bool _isAppActive = true;
  bool _isLottieLoaded = false;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    setState(() {
      _isAppActive = state == AppLifecycleState.resumed;
      _updateAnimationState();
    });
  }

  void _updateAnimationState() {
    if (_isAppActive && _isTabVisible && _isLottieLoaded) {
      _lottieController.repeat();
    } else {
      _lottieController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUserId = ref
        .watch(authStateProvider)
        .value
        ?.session
        ?.user
        .id;
    final targetUserId = widget.userId ?? currentAuthUserId;
    final isCurrentUserProfile = targetUserId == currentAuthUserId;

    ref.watch(profileRealtimeProvider);
    ref.watch(achievementRealtimeProvider);
    ref.watch(followRealtimeProvider);

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Usuario no encontrado")));
    }

    final colors = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return VisibilityDetector(
      key: Key('profile-view-detector-$targetUserId'),
      onVisibilityChanged: (visibilityInfo) {
        setState(() {
          _isTabVisible = visibilityInfo.visibleFraction > 0.1;
          _updateAnimationState();
        });
      },
      child: Scaffold(
        body: Stack(
          children: [
            _ProfileBackground(userId: targetUserId, colors: colors),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 56),
                      ProfileHeader(
                        userId: targetUserId,
                        isCurrentUserProfile: isCurrentUserProfile,
                        isAppActive: _isAppActive,
                        isTabVisible: _isTabVisible,
                      ),
                      if (!isCurrentUserProfile)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 30.0,
                            bottom: 20.0,
                          ),
                          child: SizedBox(
                            width: 300,
                            child: FollowButton(userId: targetUserId),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              isDarkMode
                                  ? colors.secondaryFixedDim.withAlpha(77)
                                  : colors.secondary.withAlpha(102),
                              BlendMode.srcIn,
                            ),
                            child: Lottie.asset(
                              'assets/animations/particles.json',
                              fit: BoxFit.cover,

                              frameRate: FrameRate(30),
                              controller: _lottieController,
                              onLoaded: (composition) {
                                _lottieController.duration =
                                    composition.duration;
                                _isLottieLoaded = true;
                                _updateAnimationState();
                              },
                            ),
                          ),
                        ),
                      ),

                      ListView(
                        padding: EdgeInsets.only(
                          top: isCurrentUserProfile ? 20.0 : 0,
                          bottom: 70.0,
                        ),
                        children: [
                          FadeInUp(
                            from: 30,
                            delay: const Duration(milliseconds: 300),
                            child: ProfileProgressSection(
                              userId: targetUserId,
                              showViewAllButton: isCurrentUserProfile,
                              enableGlassEffect: _isTabVisible && _isAppActive,
                            ),
                          ),
                          FadeInUp(
                            from: 30,
                            delay: const Duration(milliseconds: 400),
                            child: ProfileAchievementsSection(
                              userId: targetUserId,
                              isCurrentUserProfile: isCurrentUserProfile,
                              enableGlassEffect: _isTabVisible && _isAppActive,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _TopBar(
                  isCurrentUserProfile: isCurrentUserProfile,
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBackground extends ConsumerWidget {
  final String userId;
  final ColorScheme colors;

  const _ProfileBackground({required this.userId, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarId = ref.watch(
      userProfileByIdProvider(
        userId,
      ).select((data) => data.value?.idAvatarSeleccionado),
    );

    final avatarsList = ref.watch(currentUserAvatarsProvider).value ?? [];

    final dynamicColor = (avatarId != null && avatarsList.isNotEmpty)
        ? getAvatarColorById(avatarId, avatarsList)
        : colors.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            dynamicColor.withAlpha((255 * 0.4).round()),
            colors.surfaceContainerLowest,
          ],
          stops: const [0.0, 0.6],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isCurrentUserProfile;
  final ColorScheme colors;

  const _TopBar({required this.isCurrentUserProfile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isCurrentUserProfile)
            InkWell(
              onTap: () {
                context.push('/settings');
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: colors.surface.withAlpha((255 * 0.3).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.settings_outlined, color: colors.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
