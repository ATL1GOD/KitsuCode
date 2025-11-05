// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  // Obtener el ID del usuario autenticado (asumiendo que está disponible)
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  // Función clave para el desafío mensual
  Future<Map<String, dynamic>?> getRetoMensualData({
    required int tipoRetoId,
  }) async {
    // 1. Obtener el reto activo que es de tipo 'mensual'
    // Se recomienda usar `rpc` o `functions` para lógica más compleja de "reto mensual"
    final List<Map<String, dynamic>> retos = await _client
        .from('reto')
        .select()
        .eq('tipo_reto', tipoRetoId) // Asumimos 2 es el tipo_reto mensual
        .eq('activo', true)
        .limit(1);

    if (retos.isEmpty) return null;

    final Map<String, dynamic> retoData = retos.first;
    final int idReto = retoData['id_reto'];

    // 2. Verificar si el usuario ya ha completado este reto
    final List<Map<String, dynamic>> intentos = await _client
        .from('intento_reto')
        .select()
        .eq('id_usuario', _userId)
        .eq('id_reto', idReto)
        // Podrías añadir lógica de `resultado` si solo cuenta el intento exitoso
        .limit(1);

    final bool completado = intentos.isNotEmpty;

    return {'retoData': retoData, 'completado': completado};
  }

  // Otras funciones como getEstadisticas, etc.
}
