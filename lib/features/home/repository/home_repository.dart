// features/core/providers/supabase_provider.dart
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

// 2. Clase del Repositorio
class SectionRepository {
  final SupabaseClient _client;

  SectionRepository(this._client);

  // Método modificado para obtener las secciones Y sus niveles
  Future<List<SectionData>> getSections() async {
    try {
      // 1. Llama a la tabla 'secciones' de Supabase
      final response = await _client
          .from('secciones')
          .select('*, seccion_niveles(*)') // Carga secciones y sus niveles
          .order('etapa', ascending: true) // OK: 'etapa' sí existe
          // CORRECCIÓN CLAVE: Usamos 'id_seccion' o 'titulo' en lugar de 'seccion'
          .order('id_seccion', ascending: true);

      // 2. Convierte la lista de JSON (List<Map<String, dynamic>>)
      //    en una lista de objetos SectionData
      final sections = response
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      // DEBUG: Para verificar cuántas secciones se cargan realmente
      print("Supabase: ${sections.length} secciones cargadas.");

      return sections;
    } catch (e) {
      // Maneja el error apropiadamente
      print(
        "Error en SectionRepository: $e",
      ); // Aquí aparecerá el error corregido
      throw Exception('No se pudieron cargar las secciones');
    }
  }
}
