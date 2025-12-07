import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/model/challenge_history_model.dart';
import 'package:kitsucode/features/profile/model/avatar_model.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:kitsucode/shared/widgets/achievement_toast.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:collection';

import 'package:kitsucode/core/providers/connectivity_provider.dart';

final globalToastLockProvider = StateProvider<bool>((ref) => false);
Color _safeParseColor(String colorString) {
  try {
    return Color(int.parse(colorString));
  } catch (e) {
    debugPrint('Error al parsear color "$colorString": $e');
    return const Color(0xFF9E9E9E);
  }
}

final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
});

final userProfileByIdProvider = StreamProvider.autoDispose
    .family<UserProfileModel, String>((ref, userId) {
      final connectivity = ref.watch(connectivityProvider);

      return connectivity.when(
        data: (status) {
          if (status == ConnectivityStatus.online) {
            final profileRepository = ref.watch(profileRepositoryProvider);
            return profileRepository.watchUserProfileById(userId);
          } else {
            return Stream.error('Sin conexión');
          }
        },

        loading: () => const Stream.empty(),

        error: (e, s) => Stream.error(e),
      );
    });

final userAchievementsProvider =
    FutureProvider.family<List<UserAchievementModel>, String>((
      ref,
      userId,
    ) async {
      final connectivityStatus = await ref.watch(connectivityProvider.future);

      if (connectivityStatus != ConnectivityStatus.online) {
        throw Exception('Sin conexión');
      }

      final profileRepository = ref.watch(profileRepositoryProvider);
      return profileRepository.fetchUserAchievementsById(userId);
    });

final userStatsByIdProvider = FutureProvider.autoDispose
    .family<UserStatsModel, String>((ref, userId) async {
      final connectivityStatus = await ref.watch(connectivityProvider.future);
      if (connectivityStatus != ConnectivityStatus.online) {
        throw Exception('Sin conexión');
      }

      final repository = ref.watch(profileRepositoryProvider);
      return repository.fetchUserStatsById(userId);
    });

final userAvatarsProvider = FutureProvider.family
    .autoDispose<List<AvatarModel>, String>((ref, userId) async {
      final connectivityStatus = await ref.watch(connectivityProvider.future);
      if (connectivityStatus != ConnectivityStatus.online) {
        throw Exception('Sin conexión');
      }

      ref.keepAlive();
      final repository = ref.watch(profileRepositoryProvider);
      return repository.fetchUserAvatars(userId);
    });

final currentUserAvatarsProvider =
    FutureProvider.autoDispose<List<AvatarModel>>((ref) async {
      final userId = ref.watch(authStateProvider).value?.session?.user.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      return ref.watch(userAvatarsProvider(userId).future);
    });

final followRealtimeProvider = Provider.autoDispose((ref) {
  ref.watch(authStateProvider);

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final channel = supabase.channel('public:seguimiento_usuario');

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'seguimiento_usuario',
        callback: (payload) {
          final eventType = payload.eventType;
          final record = eventType == PostgresChangeEvent.insert
              ? payload.newRecord
              : payload.oldRecord;

          if (record.isNotEmpty) {
            final followerId = record['id_usuario'];
            final followedId = record['id_usuario_seguido'];

            ref.invalidate(userProfileByIdProvider(followerId));
            ref.invalidate(userProfileByIdProvider(followedId));
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
  return channel;
});

final profileRealtimeProvider = Provider.autoDispose((ref) {
  ref.watch(authStateProvider);

  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  final userChannel = supabase.channel('public:usuarios:profile');
  userChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'usuarios',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          ref.invalidate(userProfileByIdProvider(userId));
        },
      )
      .subscribe();

  final statsChannel = supabase.channel('public:estadistica_usuario:profile');
  statsChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'estadistica_usuario',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id_usuario',
          value: userId,
        ),
        callback: (payload) {
          ref.invalidate(userStatsByIdProvider(userId));
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(userChannel);
    supabase.removeChannel(statsChannel);
  });
});

final achievementRealtimeProvider = Provider.autoDispose((ref) {
  ref.watch(authStateProvider);

  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return;

  final channelsToCleanup = <RealtimeChannel>[];
  final earnedChannel = supabase.channel('public:usuario_logro_earned');
  channelsToCleanup.add(earnedChannel);

  earnedChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'usuario_logro',
        callback: (payload) {
          final newRecord = payload.newRecord;
          if (newRecord.isNotEmpty) {
            final userId = newRecord['id_usuario'];
            if (userId != null) {
              ref.invalidate(userAchievementsProvider(userId));
            }
          }
        },
      )
      .subscribe();

  final globalAchievementChannel = supabase.channel('public:logro_definition');
  channelsToCleanup.add(globalAchievementChannel);

  void globalAchievementCallback(dynamic payload) {
    ref.invalidate(userAchievementsProvider(currentUserId));
  }

  globalAchievementChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'logro',
        callback: globalAchievementCallback,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'logro',
        callback: globalAchievementCallback,
      )
      .subscribe();

  ref.onDispose(() {
    for (final channel in channelsToCleanup) {
      supabase.removeChannel(channel);
    }
  });

  return;
});

class AchievementNotificationData {
  final String nombreLogro;
  final String iconUrl;
  final String raridad;

  AchievementNotificationData({
    required this.nombreLogro,
    required this.iconUrl,
    required this.raridad,
  });
}

class AchievementNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final Queue<AchievementNotificationData> _queue = Queue();

  AchievementNotifier(this._ref) : super(false) {
    _initListener();

    _ref.listen(globalToastLockProvider, (previous, next) {
      if (next == false) {
        _processQueue();
      }
    });
  }

  void _initListener() {
    final supabase = Supabase.instance.client;
    final authState = _ref.read(authStateProvider);
    final currentUserId = authState.value?.session?.user.id;
    if (currentUserId == null) return;

    final channel = supabase.channel('public:usuario_logro_toast_v2');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'usuario_logro',
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) return;
              if (newRecord['id_usuario'] == currentUserId) {
                final logroId = newRecord['id_logro'] as int;
                final details = await _ref
                    .read(profileRepositoryProvider)
                    .fetchLogroDetails(logroId);
                final notificationData = AchievementNotificationData(
                  nombreLogro: details['nombre'] ?? 'Logro Desbloqueado',
                  iconUrl: details['icono'] ?? 'assets/images/zorro_oops.webp',
                  raridad: details['raridad'] ?? 'Común',
                );
                _addToQueue(notificationData);
              }
            } catch (e) {
              debugPrint('Error al recibir notificación de logro: $e');
            }
          },
        )
        .subscribe();

    state = true;
    _ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }

  void _addToQueue(AchievementNotificationData data) {
    _queue.add(data);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || _ref.read(globalToastLockProvider)) {
      return;
    }
    _ref.read(globalToastLockProvider.notifier).state = true;

    final notificationData = _queue.removeFirst();
    showSimpleNotification(
      AchievementToast(
        title: "¡Logro Desbloqueado!",
        nombreLogro: notificationData.nombreLogro,
        iconUrl: notificationData.iconUrl,
        raridad: notificationData.raridad,
      ),
      background: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 4),
    );

    await Future.delayed(const Duration(seconds: 5));
    _ref.read(globalToastLockProvider.notifier).state = false;
  }
}

final achievementNotifierProvider =
    StateNotifierProvider.autoDispose<AchievementNotifier, bool>((ref) {
      ref.watch(authStateProvider);
      return AchievementNotifier(ref);
    });

class AvatarNotificationData {
  final String nombreAvatar;
  final String assetPath;
  final String tipo;
  final String colorPrimario;

  AvatarNotificationData({
    required this.nombreAvatar,
    required this.assetPath,
    required this.tipo,
    required this.colorPrimario,
  });
}

class AvatarNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final Queue<AvatarNotificationData> _queue = Queue();

  AvatarNotifier(this._ref) : super(false) {
    _initListener();

    _ref.listen(globalToastLockProvider, (previous, next) {
      if (next == false) {
        _processQueue();
      }
    });
  }

  void _initListener() {
    final supabase = Supabase.instance.client;
    final authState = _ref.read(authStateProvider);
    final currentUserId = authState.value?.session?.user.id;
    if (currentUserId == null) return;

    final channel = supabase.channel('public:usuario_avatar_toast');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'usuario_avatar',
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) return;
              if (newRecord['id_usuario'] == currentUserId) {
                final avatarId = newRecord['id_avatar'] as int;
                final details = await _ref
                    .read(profileRepositoryProvider)
                    .fetchAvatarDetails(avatarId);
                final notificationData = AvatarNotificationData(
                  nombreAvatar: details['nombre'] ?? 'Avatar Desbloqueado',
                  assetPath:
                      details['asset_path'] ?? 'assets/images/zorro_oops.webp',
                  tipo: details['tipo'] ?? 'Especial',
                  colorPrimario: details['color_primario'] ?? '0xFF9E9E9E',
                );

                _ref.invalidate(userAvatarsProvider(currentUserId));
                _addToQueue(notificationData);
              }
            } catch (e) {
              debugPrint('Error al recibir notificación de avatar: $e');
            }
          },
        )
        .subscribe();

    state = true;
    _ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }

  void _addToQueue(AvatarNotificationData data) {
    _queue.add(data);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || _ref.read(globalToastLockProvider)) {
      return;
    }
    _ref.read(globalToastLockProvider.notifier).state = true;

    final notificationData = _queue.removeFirst();
    final Color avatarColor = _safeParseColor(notificationData.colorPrimario);

    showSimpleNotification(
      AchievementToast(
        title: "¡Avatar Desbloqueado!",
        nombreLogro: notificationData.nombreAvatar,
        iconUrl: notificationData.assetPath,
        raridad: notificationData.tipo,
        borderColor: avatarColor,
      ),
      background: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 4),
    );

    await Future.delayed(const Duration(seconds: 5));
    _ref.read(globalToastLockProvider.notifier).state = false;
  }
}

final avatarNotifierProvider =
    StateNotifierProvider.autoDispose<AvatarNotifier, bool>((ref) {
      ref.watch(authStateProvider);
      return AvatarNotifier(ref);
    });

final historyDateRangeProvider = StateProvider.autoDispose<DateTimeRange>((
  ref,
) {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  return DateTimeRange(start: thirtyDaysAgo, end: now);
});

final challengeHistoryProvider = FutureProvider.autoDispose
    .family<List<ChallengeHistoryModel>, String>((ref, userId) async {
      final connectivityStatus = await ref.watch(connectivityProvider.future);
      if (connectivityStatus != ConnectivityStatus.online) {
        throw Exception('Sin conexión');
      }

      final profileRepo = ref.watch(profileRepositoryProvider);
      final dateRange = ref.watch(historyDateRangeProvider);
      return profileRepo.getChallengeHistory(
        userId,
        startDate: dateRange.start,
        endDate: dateRange.end,
      );
    });
