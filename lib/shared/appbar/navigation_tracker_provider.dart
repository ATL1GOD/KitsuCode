// lib/shared/appbar/navigation_tracker_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que rastrea si el usuario ha salido del Home
/// y debe refrescar las estadísticas cuando regrese
final shouldRefreshStatsProvider = StateProvider<bool>((ref) => false);

/// Provider que guarda los valores antiguos de stats para la animación
/// Guardamos: [vidas, trofeos, racha]
final oldStatsValuesProvider = StateProvider<List<int>?>((ref) => null);

/// Función helper para marcar que se debe refrescar cuando se regrese al Home
void markForStatsRefresh(WidgetRef ref) {
  ref.read(shouldRefreshStatsProvider.notifier).state = true;
}
