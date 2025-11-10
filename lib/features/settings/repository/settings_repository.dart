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
      final userId = _supabaseClient.auth.currentUser!.id;
      final response = await _supabaseClient
          .from('preferencias_usuario')
          .select()
          .eq('id_usuario', userId)
          .single(); // .single() espera un solo registro o lanza error

      return PreferenciasUsuarioModel.fromJson(response);
    } catch (e) {
      // Manejo de error: si no existe, crea y devuelve preferencias por defecto
      if (e is PostgrestException && e.code == 'PGRST116') {
        return await _crearPreferenciasPorDefecto();
      }
      rethrow; // Lanza cualquier otro error
    }
  }

  // Actualiza un campo específico de las preferencias
  Future<void> updatePreferencia(Map<String, dynamic> data) async {
    try {
      final userId = _supabaseClient.auth.currentUser!.id;
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
    final userId = _supabaseClient.auth.currentUser!.id;
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