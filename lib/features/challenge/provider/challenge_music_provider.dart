import 'package:flutter_riverpod/flutter_riverpod.dart';

final isInChallengeProvider = StateProvider<bool>((ref) => false);

void pauseMusicForChallenge(WidgetRef ref) {
  ref.read(isInChallengeProvider.notifier).state = true;
}

void resumeMusicAfterChallenge(WidgetRef ref) {
  ref.read(isInChallengeProvider.notifier).state = false;
}
