// lib/features/challenge/provider/challenge_music_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que rastrea si el usuario está dentro de un reto
final isInChallengeProvider = StateProvider<bool>((ref) => false);

/// Función helper para pausar la música al entrar a un reto
void pauseMusicForChallenge(WidgetRef ref) {
  ref.read(isInChallengeProvider.notifier).state = true;
}

/// Función helper para reanudar la música al salir de un reto
void resumeMusicAfterChallenge(WidgetRef ref) {
  ref.read(isInChallengeProvider.notifier).state = false;
}