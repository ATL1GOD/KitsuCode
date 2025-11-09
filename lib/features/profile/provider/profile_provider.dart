// lib/features/profile/provider/profile_provider.dart para datos de prueba en profile

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/profile/model/user_profile_model.dart';
import 'package:kitsucode/features/profile/repository/profile_repository.dart';
import 'package:kitsucode/features/profile/model/user_stats_model.dart';
import 'package:kitsucode/features/profile/model/user_achievement_model.dart';
import 'package:kitsucode/features/profile/repository/mock_profile_repository.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para el repositorio de perfil
final profileRepositoryProvider = Provider((ref) {
  final supabaseClient = Supabase.instance.client;
  return ProfileRepository(supabaseClient);
  //return MockProfileRepository(); 
});

// Provider para obtener el perfil de un usuario por su ID
// --- CAMBIO CLAVE: De FutureProvider a StreamProvider ---
final userProfileByIdProvider = StreamProvider.family<UserProfileModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  // Llamamos al nuevo método que devuelve un Stream
  return profileRepository.watchUserProfileById(userId);
});

// Los providers de estadísticas y logros pueden seguir siendo FutureProviders
// ya que el userProfileProvider los invalidará si es necesario, o se pueden
final userStatsProvider = FutureProvider.family<UserStatsModel, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserStatsById(userId);
});

final userAchievementsProvider = FutureProvider.family<List<UserAchievementModel>, String>((ref, userId) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return profileRepository.fetchUserAchievementsById(userId);
});

// El realtime provider para seguimiento sigue igual.
final followRealtimeProvider = Provider((ref) {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('public:seguimiento_usuario');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'seguimiento_usuario',
    callback: (payload) {
      // ignore: avoid_print
      print('Cambio detectado en seguimiento_usuario: $payload');
      final eventType = payload.eventType;
      final record = eventType == PostgresChangeEvent.insert ? payload.newRecord : payload.oldRecord;

      if (record.isNotEmpty) {
        final followerId = record['id_usuario'];
        final followedId = record['id_usuario_seguido'];

        // Se invalidan los perfiles de ambos usuarios para actualizar contadores
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