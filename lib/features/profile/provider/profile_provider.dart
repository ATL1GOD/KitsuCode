// [COMIENZO DEL ARCHIVO profile_provider.dart]
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
import 'dart:ui'; // Import para la clase Color

// 🔥 1. IMPORTAR EL CONNECTIVITY PROVIDER
import 'package:kitsucode/core/providers/connectivity_provider.dart';

// ✅ 1. EL CANDADO GLOBAL
// (Tu código de candado y notifiers está perfecto, no se toca)
final globalToastLockProvider = StateProvider<bool>((ref) => false);
Color _safeParseColor(String colorString) {
  try {
    return Color(int.parse(colorString));
  } catch (e) {
    debugPrint('Error al parsear color "$colorString": $e');
    return const Color(0xFF9E9E9E); // Gris
  }
}

// Provider para el repositorio de perfil
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
});

// Provider para obtener el perfil de un usuario por su ID
// 🔥 MODIFICADO: Ahora reacciona a la conexión
final userProfileByIdProvider =
    StreamProvider.family<UserProfileModel, String>((ref, userId) {
  // "Escuchar" la conexión
  final connectivity = ref.watch(connectivityProvider);

  // Usar .when para manejar el estado de la conexión
  return connectivity.when(
    data: (status) {
      if (status == ConnectivityStatus.online) {
        // CONECTADO: Devolver el stream real
        final profileRepository = ref.watch(profileRepositoryProvider);
        return profileRepository.watchUserProfileById(userId);
      } else {
        // OFFLINE: Devolver un stream que emite un error
        return Stream.error('Sin conexión');
      }
    },
    // CARGANDO CONEXIÓN: Devolver un stream vacío mientras se verifica
    loading: () => const Stream.empty(),
    // ERROR DE CONEXIÓN: Devolver un stream con el error
    error: (e, s) => Stream.error(e),
  );
});

// Provider para los logros
// 🔥 MODIFICADO: Ahora reacciona a la conexión
final userAchievementsProvider =
    FutureProvider.family<List<UserAchievementModel>, String>(
        (ref, userId) async {
  // Esperar a que la conexión esté confirmada
  final connectivityStatus = await ref.watch(connectivityProvider.future);

  // Si no estamos 'online', lanza un error
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }

  // --- LÓGICA ORIGINAL ---
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievementsById(userId);
});

// 🔥 MODIFICADO: Ahora reacciona a la conexión
final userStatsByIdProvider =
    FutureProvider.autoDispose.family<UserStatsModel, String>((ref, userId) async {
  final connectivityStatus = await ref.watch(connectivityProvider.future);
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }
  
  // --- LÓGICA ORIGINAL ---
  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchUserStatsById(userId);
});

// ==================== PROVIDERS PARA AVATARES ====================
// 🔥 MODIFICADO: Ahora reacciona a la conexión
final userAvatarsProvider = FutureProvider.family
    .autoDispose<List<AvatarModel>, String>((ref, userId) async {
  final connectivityStatus = await ref.watch(connectivityProvider.future);
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }

  // --- LÓGICA ORIGINAL ---
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
  // No necesita check de conexión, porque 'userAvatarsProvider' ya lo tiene.
  // Si 'userAvatarsProvider' falla, este también lo hará.
  return ref.watch(userAvatarsProvider(userId).future);
});

// ==================== FIN PROVIDERS AVATARES ====================

// --- Providers de Realtime (No necesitan cambios) ---
// (Tu código de followRealtimeProvider, profileRealtimeProvider, 
// achievementRealtimeProvider, AchievementNotifier, AvatarNotifier, etc. 
// se queda exactamente igual que antes, ya que son event-driven 
// y no hacen un fetch inicial que pueda fallar por conexión)

final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');
  // ... (tu código de realtime de seguimiento) ...
  channel.onPostgresChanges(
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
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
  return channel;
});

final profileRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  // ... (tu código de realtime de perfil) ...
  final userChannel = supabase.channel('public:usuarios:profile');
  userChannel.onPostgresChanges(
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
  ).subscribe();

  final statsChannel = supabase.channel('public:estadistica_usuario:profile');
  statsChannel.onPostgresChanges(
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
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(userChannel);
    supabase.removeChannel(statsChannel);
  });
});

final achievementRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId == null) return;
  // ... (tu código de realtime de logros) ...
  final channelsToCleanup = <RealtimeChannel>[];
  final earnedChannel = supabase.channel('public:usuario_logro_earned');
  channelsToCleanup.add(earnedChannel);

  earnedChannel.onPostgresChanges(
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
  ).subscribe();

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

// --- PASO 1: Modelo de datos de Logros ---
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

// --- PASO 2: Notifier de Logros ---
class AchievementNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final Queue<AchievementNotificationData> _queue = Queue();
  // final bool _isDisplaying = false; // <-- ✅ 2. BORRADO

  AchievementNotifier(this._ref) : super(false) {
    _initListener();

    // ✅ 3. AÑADIDO: Escucha el candado global
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
    channel.onPostgresChanges(
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
              iconUrl: details['icono'] ?? 'assets/images/zorro_oops.png',
              raridad: details['raridad'] ?? 'Común',
            );
            _addToQueue(notificationData);
          }
        } catch (e) {
          debugPrint('Error al recibir notificación de logro: $e');
        }
      },
    ).subscribe();

    state = true;
    _ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }

  // ✅ 4. MODIFICADO: Llama a _processQueue
  void _addToQueue(AchievementNotificationData data) {
    _queue.add(data);
    _processQueue(); // Intenta procesar la fila
  }

  // ✅ 5. MODIFICADO: Usa el candado global
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

// --- PASO 3: Provider de Logros ---
final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, bool>((ref) {
  return AchievementNotifier(ref);
});

// ===================================================================
// ¡COMIENZA LA SECCIÓN DE AVATARES!
// ===================================================================

// --- PASO 1 (AVATAR): Modelo de datos ---
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

// --- PASO 2 (AVATAR): Notifier de Avatares ---
class AvatarNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final Queue<AvatarNotificationData> _queue = Queue();
  // final bool _isDisplaying = false; // <-- ✅ 2. BORRADO

  AvatarNotifier(this._ref) : super(false) {
    _initListener();

    // ✅ 3. AÑADIDO: Escucha el candado global
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

    channel.onPostgresChanges(
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
                  details['asset_path'] ?? 'assets/images/zorro_oops.png',
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
    ).subscribe();

    state = true;
    _ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }

  // ✅ 4. MODIFICADO: Llama a _processQueue
  void _addToQueue(AvatarNotificationData data) {
    _queue.add(data);
    _processQueue(); // Intenta procesar la fila
  }

  // ✅ 5. MODIFICADO: Usa el candado global
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

// --- PASO 3 (AVATAR): Provider de Avatares ---
final avatarNotifierProvider =
    StateNotifierProvider<AvatarNotifier, bool>((ref) {
  return AvatarNotifier(ref);
});

// --- Providers de Historial ---
final historyDateRangeProvider = StateProvider.autoDispose<DateTimeRange>((ref) {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  return DateTimeRange(start: thirtyDaysAgo, end: now);
});

// 🔥 MODIFICADO: Ahora reacciona a la conexión
final challengeHistoryProvider = FutureProvider.autoDispose
    .family<List<ChallengeHistoryModel>, String>((ref, userId) async {
  final connectivityStatus = await ref.watch(connectivityProvider.future);
  if (connectivityStatus != ConnectivityStatus.online) {
    throw Exception('Sin conexión');
  }
  
  // --- LÓGICA ORIGINAL ---
  final profileRepo = ref.watch(profileRepositoryProvider);
  final dateRange = ref.watch(historyDateRangeProvider);
  return profileRepo.getChallengeHistory(
    userId,
    startDate: dateRange.start,
    endDate: dateRange.end,
  );
});
// [FIN DEL ARCHIVO profile_provider.dart]