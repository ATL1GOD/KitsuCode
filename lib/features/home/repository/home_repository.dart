import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/home/model/home_model.dart';

// Provider que expone el cliente de Supabase (sin cambios)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 1. Provider para el Repositorio (sin cambios)
final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SectionRepository(client);
});

// 2. Clase del Repositorio
class SectionRepository {
  final SupabaseClient _client;

  SectionRepository(this._client);

  Future<List<SectionData>> getSections() async {
    try {
      final response = await _client
          .from('secciones')
          .select('''
          *, 
          niveles ( 
            id_nivel, 
            orden, 
            id_reto, 
            reto:reto!niveles_id_reto_fkey (
              id_reto,
              tipo_reto,
              dinamicas ( nombre ) 
            )
          )
          ''')
          .order('orden', ascending: true);

      final sections = response
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      print("Supabase: ${sections.length} secciones cargadas.");

      return sections;
    } catch (e) {
      print("Error en SectionRepository: $e");
      throw Exception('No se pudieron cargar las secciones: $e');
    }
  }
}
