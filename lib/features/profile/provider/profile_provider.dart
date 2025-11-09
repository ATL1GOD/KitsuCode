// lib/features/profile/provider/profile_provider.dart para datos de prueba en profile

import 'package:flutter/foundation.dart'; // <-- ¡IMPORTADO PARA debugPrint!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/repository/mock_profile_repository.dart'; 
import 'dart:convert'; // Para decodificar el JSON
import 'package:flutter/material.dart'; // Para el BuildContext
import 'package:overlay_support/overlay_support.dart'; // Para mostrar la notificación
import 'package:kitsucode/shared/widgets/achievement_toast.dart'; // El widget que creamos
import 'package:kitsucode/features/auth/provider/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

// Provider de Realtime para seguimiento (sin cambios)
final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'seguimiento_usuario',
    callback: (payload) {
      // ignore: avoid_print
      debugPrint('Cambio detectado en seguimiento_usuario: $payload');
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

// --- ¡NUEVO Provider de Realtime para el Perfil (CORREGIDO)! ---
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

  // 1. Creamos un canal para la tabla 'usuario_logro'
  final channel = supabase.channel('public:usuario_logro');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert, // <-- ¡Solo nos importa cuando se INSERTA un nuevo logro!
    schema: 'public',
    table: 'usuario_logro',
    callback: (payload) {
      // ¡Alguien ganó un logro!
      // ignore: avoid_print
      print('Cambio detectado en usuario_logro: ${payload.newRecord}');

      final newRecord = payload.newRecord;
      if (newRecord.isNotEmpty) {
        
        // 2. Obtenemos el ID del usuario que ganó el logro
        final userId = newRecord['id_usuario'];

        // 3. Invalidamos el provider de logros para ESE usuario
        // Esto forzará a la UI a recargar la lista de logros
        if (userId != null) {
          ref.invalidate(userAchievementsProvider(userId));
        }
      }
    },
  ).subscribe(); // <-- ¡No olvides suscribirte!

  // 4. Limpiamos el canal cuando el provider ya no se use
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return channel;
});

// ✅✅✅ VERSIÓN CORREGIDA DEL NOTIFIER PROVIDER ✅✅✅
final newAchievementNotifierProvider = Provider.autoDispose((ref) {
  final supabase = Supabase.instance.client;

  // ✅ ¡LA CORRECCIÓN ESTÁ AQUÍ! ✅
  // 1. Vemos el 'authStateProvider' (que es un StreamProvider)
  final authState = ref.watch(authStateProvider);
  
  // 2. Accedemos a su valor actual (value), luego a la sesión, al usuario y al ID.
  final currentUserId = authState.value?.session?.user?.id; 

  // 3. Si no hay ID de usuario (no está logueado), no hacemos nada.
  if (currentUserId == null) return null;

  final channel = supabase.channel('public:usuario_logro_toast');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'usuario_logro',
    callback: (payload) async {
      try {
        final newRecord = payload.newRecord;
        if (newRecord.isEmpty) return;

        // Verificamos si el logro es PARA MÍ (el usuario actual)
        if (newRecord['id_usuario'] == currentUserId) {
          
          // ¡Es para mí! Obtenemos los detalles del logro
          final logroId = newRecord['id_logro'] as int;
          
          final details = await ref.read(profileRepositoryProvider).fetchLogroDetails(logroId);

          final nombreLogro = details['nombre'] ?? 'Logro Desbloqueado';
          final iconUrl = details['icono'] ?? 'assets/images/zorro_oops.png';

          // ¡Mostramos la notificación!
          showSimpleNotification(
            AchievementToast(
              nombreLogro: nombreLogro,
              iconUrl: iconUrl,
            ),
            background: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        debugPrint('Error al mostrar notificación de logro: $e');
      }
    },
  ).subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });

  return channel;
});