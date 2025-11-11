import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';

// Provider para el Repositorio
final settingsRepositoryProvider = Provider((ref) {
  return SettingsRepository(supabaseClient: Supabase.instance.client);
});

class SettingsRepository {
  final SupabaseClient _supabaseClient;

  SettingsRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Obtiene las preferencias del usuario actual
  Future<PreferenciasUsuarioModel> getPreferencias() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await _supabaseClient
          .from('preferencias_usuario')
          .select()
          .eq('id_usuario', userId)
          .single(); // .single() espera un solo registro o lanza error

      return PreferenciasUsuarioModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Si no existe el registro (código PGRST116), crea uno por defecto
      if (e.code == 'PGRST116') {
        return await _crearPreferenciasPorDefecto();
      }
      rethrow;
    } catch (e) {
      // Cualquier otro error (como "Usuario no autenticado")
      rethrow;
    }
  }

  // Actualiza un campo específico de las preferencias
  Future<void> updatePreferencia(Map<String, dynamic> data) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      await _supabaseClient
          .from('preferencias_usuario')
          .update(data)
          .eq('id_usuario', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Función privada para crear preferencias si el usuario no las tiene
  Future<PreferenciasUsuarioModel> _crearPreferenciasPorDefecto() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // ¡Usamos 'system' como por defecto, tal como lo pediste!
    final preferenciasPorDefecto = PreferenciasUsuarioModel(
      temaVisual: 'system',
      sonidoEfectos: true,
      volumenAudio: 0.8,
    );

    try {
      final response = await _supabaseClient
          .from('preferencias_usuario')
          .insert({
            'id_usuario': userId,
            ...preferenciasPorDefecto.toJson(),
          })
          .select()
          .single();
      
      return PreferenciasUsuarioModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}