import 'package:flutter_riverpod/flutter_riverpod.dart';

final shouldRefreshStatsProvider = StateProvider<bool>((ref) => false);

final oldStatsValuesProvider = StateProvider<List<int>?>((ref) => null);

void markForStatsRefresh(WidgetRef ref) {
  ref.read(shouldRefreshStatsProvider.notifier).state = true;
}
