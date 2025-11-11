// lib/features/profile/provider/profile_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/provider/profile_provider.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, bool>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return ProfileController(
    profileRepository: profileRepository,
    ref: ref,
  );
});

class ProfileController extends StateNotifier<bool> {
  final ProfileRepository _profileRepository;
  final Ref _ref;

  ProfileController({
    required ProfileRepository profileRepository,
    required Ref ref,
  })  : _profileRepository = profileRepository,
        _ref = ref,
        super(false);

  Future<UserProfileModel?> updateProfile({String? newName, int? newAvatarId}) async {
    final user = _ref.read(authStateProvider).value?.session?.user;
    if (user == null) return null;

    state = true; 
    try {
      await _profileRepository.updateUserProfile(
        userId: user.id,
        newName: newName,
        newAvatarId: newAvatarId,
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _ref.invalidate(userProfileByIdProvider(user.id));
      
      final updatedProfile = await _ref.read(userProfileByIdProvider(user.id).future);
      
      state = false; 
      return updatedProfile; 
      
    } catch (e) {
      state = false; 
      return null; 
    }
  }
}