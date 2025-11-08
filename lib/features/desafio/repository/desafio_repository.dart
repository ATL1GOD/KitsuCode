// lib/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  // Obtener el ID del usuario autenticado (asumiendo que está disponible)
  // Nota: Es más seguro obtener el ID del usuario dentro de la función si el token puede expirar.
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  // Función clave para obtener todos los datos del Reto Mensual Agrupador
  Future<Map<String, dynamic>> getRetoMensualData() async {
    // 1. Obtener el Reto Agrupador Activo (tipo_reto = 5, especial = true)
    final List<Map<String, dynamic>> retosEspeciales = await _client
        .from('reto')
        .select('id_reto, fecha_inicio, fecha_final, recompensa_trofeos')
        .eq('tipo_reto', 5)
        .eq('especial', true)
        .eq('activo', true)
        .limit(1);

    if (retosEspeciales.isEmpty) {
      return {'agrupador': null, 'individuales': [], 'completedIds': {}};
    }

    final Map<String, dynamic> agrupador = retosEspeciales.first;
    final String fechaInicio = agrupador['fecha_inicio'];
    final String fechaFinal = agrupador['fecha_final'];

    // 2. Obtener los Retos Individuales que componen este Agrupador
    final List<Map<String, dynamic>> retosIndividuales = await _client
        .from('reto')
        .select('id_reto, titulo, recompensa_trofeos')
        .neq('tipo_reto', 5) // Excluir el tipo Agrupador
        .eq('especial', false) // Retos normales
        .eq('activo', true)
        .gte('fecha_inicio', fechaInicio)
        .lte('fecha_final', fechaFinal);

    final List<int> retosIndividualesIds = retosIndividuales
        .map((r) => r['id_reto'] as int)
        .toList();

    // 3. Obtener el progreso del usuario para esos retos individuales
    final List<Map<String, dynamic>> resultsCompleted = await _client
        .from('intento_reto')
        .select('id_reto')
        .eq('id_usuario', _userId)
        .eq('resultado', 'COMPLETADO')
        .inFilter('id_reto', retosIndividualesIds);

    final Set<int> completedRetoIds = resultsCompleted
        .map((item) => item['id_reto'] as int)
        .toSet();

    return {
      'agrupador': agrupador,
      'individuales': retosIndividuales,
      'completedIds': completedRetoIds,
    };
  }

  // Otras funciones como getEstadisticas, etc.
}
