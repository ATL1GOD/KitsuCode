import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/model/follow_list_model.dart';

class FollowListArgs {
  final String userId;
  final String type;

  FollowListArgs({required this.userId, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FollowListArgs &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode => userId.hashCode ^ type.hashCode;
}

final followListProvider = FutureProvider.autoDispose
    .family<List<FollowListModel>, FollowListArgs>((ref, args) {
      ref.watch(authStateProvider);

      final profileRepository = ref.watch(profileRepositoryProvider);

      return profileRepository.getFollowList(
        userId: args.userId,
        type: args.type,
      );
    });

final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  userId,
) {
  ref.watch(authStateProvider);

  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.isFollowing(userId);
});

final followControllerProvider =
    StateNotifierProvider.autoDispose<FollowController, bool>((ref) {
      final profileRepository = ref.watch(profileRepositoryProvider);

      final link = ref.keepAlive();

      final timer = Timer(const Duration(seconds: 30), () {
        link.close();
      });
      ref.onDispose(() => timer.cancel());

      return FollowController(profileRepository, ref);
    });

class FollowController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  FollowController(this._profileRepository, this._ref) : super(false);

  Future<bool> toggleFollow(
    String followedUserId, {
    FollowListArgs? currentListArgs,
  }) async {
    state = true;
    try {
      final currentUserId = _ref
          .read(authStateProvider)
          .value
          ?.session
          ?.user
          .id;

      final newFollowState = await _profileRepository.toggleFollow(
        followedUserId,
      );

      _ref.invalidate(isFollowingProvider(followedUserId));

      _ref.invalidate(userProfileByIdProvider(followedUserId));

      if (currentUserId != null) {
        _ref.invalidate(userProfileByIdProvider(currentUserId));

        _ref.invalidate(
          followListProvider(
            FollowListArgs(userId: currentUserId, type: 'following'),
          ),
        );
        _ref.invalidate(
          followListProvider(
            FollowListArgs(userId: currentUserId, type: 'followers'),
          ),
        );
      }

      if (currentListArgs != null) {
        _ref.invalidate(followListProvider(currentListArgs));

        final otherType = currentListArgs.type == 'following'
            ? 'followers'
            : 'following';
        final otherListArgs = FollowListArgs(
          userId: currentListArgs.userId,
          type: otherType,
        );
        _ref.invalidate(followListProvider(otherListArgs));
      }

      _ref.invalidate(followListProvider);

      return newFollowState;
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
}
