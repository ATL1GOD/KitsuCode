import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/settings/model/preferencias_usuario_model.dart';

final settingsRepositoryProvider = Provider((ref) {
  return SettingsRepository(supabaseClient: Supabase.instance.client);
});

class SettingsRepository {
  final SupabaseClient _supabaseClient;

  SettingsRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

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
          .single();

      return PreferenciasUsuarioModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return await _crearPreferenciasPorDefecto();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

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

  Future<PreferenciasUsuarioModel> _crearPreferenciasPorDefecto() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final preferenciasPorDefecto = PreferenciasUsuarioModel(
      temaVisual: 'system',
      sonidoEfectos: true,
      volumenAudio: 0.8,
    );

    try {
      final response = await _supabaseClient
          .from('preferencias_usuario')
          .insert({'id_usuario': userId, ...preferenciasPorDefecto.toJson()})
          .select()
          .single();

      return PreferenciasUsuarioModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
