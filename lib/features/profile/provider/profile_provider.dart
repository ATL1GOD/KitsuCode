// lib/features/profile/provider/profile_provider.dart para datos de prueba en profile

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:kitsucode/shared/widgets/achievement_toast.dart';
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:collection';

// Provider para el repositorio de perfil
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
  //return MockProfileRepository(); 
});

// Provider para obtener el perfil de un usuario por su ID
final userProfileByIdProvider = StreamProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.watchUserProfileById(userId);
});

// // Provider para las estadísticas
// final userStatsProvider = FutureProvider.autoDispose.family<UserStatsModel, String>((ref, userId) {
//     final repository = ref.watch(profileRepositoryProvider);
//     // ¡ESTA LÍNEA ESTÁ INCORRECTA!
//     return repository.fetchUserStats(); 
// });

// Provider para los logros
final userAchievementsProvider = FutureProvider.family<List<UserAchievementModel>, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievementsById(userId);
});

final userStatsByIdProvider = FutureProvider.autoDispose.family<UserStatsModel, String>((ref, userId) {
  final repository = ref.watch(profileRepositoryProvider);
  // ¡Esta es la llamada correcta!
  return repository.fetchUserStatsById(userId);
});

// Provider de Realtime para seguimiento
final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'seguimiento_usuario',
    callback: (payload) {
      final eventType = payload.eventType;
      final record = eventType == PostgresChangeEvent.insert ? payload.newRecord : payload.oldRecord;

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

// --- Provider de Realtime para el Perfil ---
final profileRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  // 1. Canal para cambios en 'usuarios' (nombre_perfil, avatar_url)
  final userChannel = supabase.channel('public:usuarios:profile');
  userChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'usuarios',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: userId,
    ),
    callback: (payload) {
      debugPrint("CAMBIO EN USUARIOS (PERFIL) DETECTADO -> Invalidando providers de perfil");
      // --- ¡ARREGLADO! ---
      // Invalidamos el provider de datos, no el controlador
      ref.invalidate(userProfileByIdProvider(userId));
    },
  ).subscribe();

  // 2. Canal para cambios en 'estadistica_usuario' (retos_completados, etc.)
  final statsChannel = supabase.channel('public:estadistica_usuario:profile');
  statsChannel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'estadistica_usuario',
    // --- ¡ARREGLADO! ---
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id_usuario',
      value: userId,
    ),
    callback: (payload) {
      debugPrint("CAMBIO EN ESTADISTICAS (STATS) DETECTADO -> Invalidando providers de perfil");
      // --- ¡ARREGLADO! ---
      // Invalidamos el provider de datos, no el controlador
      ref.invalidate(userStatsByIdProvider(userId));
    },
  ).subscribe();

  // Limpiar canales
  ref.onDispose(() {
    supabase.removeChannel(userChannel);
    supabase.removeChannel(statsChannel);
  });
});

final achievementRealtimeProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  
  if (currentUserId == null) return;

  final channelsToCleanup = <RealtimeChannel>[];

  // --- 1. Listener para cuando un USUARIO GANA UN LOGRO (Tu lógica original) ---
  // Se encarga de actualizar la lista de logros si el usuario actual (o cualquier otro que se esté viendo) gana uno.
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
          // Invalida la lista de logros para el usuario que ganó el logro
          ref.invalidate(userAchievementsProvider(userId)); 
        }
      }
    },
  ).subscribe();

  // Listener para cambios GLOBALES en la tabla de logros (C/D)
  final globalAchievementChannel = supabase.channel('public:logro_definition');
  channelsToCleanup.add(globalAchievementChannel);
  
  // Callback sin guión bajo inicial (evita el warning)
  void globalAchievementCallback(dynamic payload) {
    debugPrint("Realtime: Logro GLOBAL (C/D) detectado. Forzando recarga de lista.");
    
    // Forzamos la recarga de la lista de logros del usuario actual.
    ref.invalidate(userAchievementsProvider(currentUserId)); 
  }
  
  // Suscribimos a INSERT y DELETE en una secuencia encadenada.
  globalAchievementChannel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert, // Evento 1: CREACIÓN
        schema: 'public',
        table: 'logro',
        callback: globalAchievementCallback,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete, // Evento 2: ELIMINACIÓN
        schema: 'public',
        table: 'logro',
        callback: globalAchievementCallback,
      )
      .subscribe();


  // 3. Limpieza: Eliminar todos los canales al desecharse el provider
  ref.onDispose(() {
    for (final channel in channelsToCleanup) {
      supabase.removeChannel(channel);
    }
  });

  // No retornamos nada, solo usamos el side-effect
  return; 
});

// --- PASO 1: Un modelo simple para los datos de la notificación ---
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

// --- PASO 2: El StateNotifier que maneja la fila de espera ---
class AchievementNotifier extends StateNotifier<bool> {
  final Ref _ref;
  // La fila de espera para logros pendientes
  final Queue<AchievementNotificationData> _queue = Queue();
  // Un "seguro" para saber si ya estamos mostrando una notificación
  bool _isDisplaying = false;

  AchievementNotifier(this._ref) : super(false) {
    _initListener(); // Inicia la escucha al crearse
  }

  // El "Oído" que escucha Supabase
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
            // ¡Logro ganado!
            final logroId = newRecord['id_logro'] as int;
            final details = await _ref.read(profileRepositoryProvider).fetchLogroDetails(logroId);

            final notificationData = AchievementNotificationData(
              nombreLogro: details['nombre'] ?? 'Logro Desbloqueado',
              iconUrl: details['icono'] ?? 'assets/images/zorro_oops.png',
              raridad: details['raridad'] ?? 'Común',
            );

            // ¡En lugar de mostrarla, la añadimos a la fila!
            _addToQueue(notificationData);
          }
        } catch (e) {
          debugPrint('Error al recibir notificación de logro: $e');
        }
      },
    ).subscribe();

    state = true; // Marcamos que el listener está activo
    _ref.onDispose(() {
      supabase.removeChannel(channel);
    });
  }

  // Método público para añadir un logro a la fila
  void _addToQueue(AchievementNotificationData data) {
    _queue.add(data);
    _processQueue(); // Intenta procesar la fila
  }

  // El "Cerebro" que procesa la fila uno por uno
  Future<void> _processQueue() async {
    // Si la fila está vacía, o si ya estamos mostrando un logro, no hacemos nada.
    if (_queue.isEmpty || _isDisplaying) {
      return;
    }

    // ¡Hay un logro y no estamos ocupados!
    _isDisplaying = true; // Ponemos el "seguro"

    // 1. Sacamos el logro de la fila
    final notificationData = _queue.removeFirst();

    // 2. Mostramos la notificación
    showSimpleNotification(
      AchievementToast(
        nombreLogro: notificationData.nombreLogro,
        iconUrl: notificationData.iconUrl,
        raridad: notificationData.raridad,
      ),
      background: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 4),
    );

    // 3. Esperamos a que la notificación termine (4s) + 1s de animación de salida
    await Future.delayed(const Duration(seconds: 5));

    _isDisplaying = false; // Quitamos el "seguro"
    
    // 4. Volvemos a llamar a la función por si hay más logros en la fila
    _processQueue();
  }
}

// --- PASO 3: El Provider que crea y mantiene vivo nuestro Notifier ---
final achievementNotifierProvider = StateNotifierProvider<AchievementNotifier, bool>((ref) {
  return AchievementNotifier(ref);
});