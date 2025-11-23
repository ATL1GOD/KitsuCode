// [COMIENZO DEL ARCHIVO home_repository.dart]
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/home/model/home_model.dart';

// 0. Clase contenedora para los datos
class HomeMapData {
  final List<SectionData> sections;
  final Set<int> completedLevelIds;

  HomeMapData({required this.sections, required this.completedLevelIds});
}

// Provider que expone el cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 1. Provider para el Repositorio
final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SectionRepository(client);
});

// 2. Clase del Repositorio (¡¡MODIFICADA!!)
class SectionRepository {
  final SupabaseClient _client;
  SectionRepository(this._client);

  // Esta función ahora devuelve AMBAS listas
  Future<HomeMapData> getHomeMapData(int languageId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
      // --- CONSULTA 1: Trae la ESTRUCTURA del mapa ---
      // (Quitamos 'progreso_usuario' de aquí)
      final sectionsResponse = await _client
          .from('secciones')
          .select('''
          id_seccion,
          titulo,
          color,
          coloroscuro,
          descripcion,
          orden,
          niveles ( 
            id_nivel, 
            orden, 
            id_reto, 
            reto:reto!niveles_id_reto_fkey (
              dinamicas ( nombre ) 
            )
          )
          ''')
          .eq('id_lenguaje', languageId)
          .order('orden', ascending: true) // Ordena Secciones
          .order(
            'orden',
            referencedTable: 'niveles',
            ascending: true,
          ); // Ordena Niveles

      // Parsea las secciones
      final sections = sectionsResponse
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      // --- CONSULTA 2: Trae el PROGRESO del usuario ---
      // (Una consulta simple y separada)
      final progressResponse = await _client
          .from('progreso_usuario')
          .select('id_nivel') // Solo necesitamos los IDs
          .eq('id_usuario', currentUserId);

      // Convierte la respuesta en un Set (para búsquedas rápidas)
      final completedLevelIds = progressResponse
          .map<int>((json) => json['id_nivel'] as int)
          .toSet();

      // --- Devuelve ambos resultados ---
      return HomeMapData(
        sections: sections,
        completedLevelIds: completedLevelIds,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error en SectionRepository: $e");
      }
      throw Exception('No se pudieron cargar las secciones: $e');
    }
  }
}
// [FIN DEL ARCHIVO home_repository.dart]