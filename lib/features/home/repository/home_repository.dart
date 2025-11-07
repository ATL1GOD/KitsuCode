// [COMIENZO DEL ARCHIVO home_repository.dart]
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/home/model/home_model.dart';

// Provider que expone el cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 1. Provider para el Repositorio
final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SectionRepository(client);
});

// 2. Clase del Repositorio (MODIFICADA)
class SectionRepository {
  final SupabaseClient _client;

  SectionRepository(this._client);

  Future<List<SectionData>> getSections(int languageId) async {
    final currentUserId = _client.auth.currentUser?.id;

    if (currentUserId == null) {
      // Si RLS está bien configurado, esto no es un problema,
      // la subconsulta de progreso_usuario simplemente devolverá vacío.
      print("Advertencia: No hay usuario autenticado.");
    }

    try {
      // --- ESTA ES LA CONSULTA CLAVE ---
      final response = await _client
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
            ),
            progreso_usuario!left ( 
              id_usuario
            )
          )
          ''')
          .eq('id_lenguaje', languageId)
          // 1. Ordena las Secciones
          .order('orden', ascending: true)
          // 2. Ordena los Niveles anidados
          .order('orden', referencedTable: 'niveles', ascending: true);
      // --- FIN DE LA CONSULTA ---

      final sections = response
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      return sections;
    } catch (e) {
      print("Error en SectionRepository: $e");
      throw Exception('No se pudieron cargar las secciones: $e');
    }
  }
}
// [FIN DEL ARCHIVO home_repository.dart]