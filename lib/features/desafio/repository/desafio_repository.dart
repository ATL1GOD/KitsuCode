import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  Future<Map<String, dynamic>> getRetoMensualData() async {
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

    final List<Map<String, dynamic>> retosIndividuales = await _client
        .from('reto')
        .select('id_reto, titulo, recompensa_trofeos')
        .neq('tipo_reto', 5)
        .eq('especial', false)
        .eq('activo', true)
        .gte('fecha_inicio', fechaInicio)
        .lte('fecha_final', fechaFinal);

    final List<int> retosIndividualesIds = retosIndividuales
        .map((r) => r['id_reto'] as int)
        .toList();

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
}
