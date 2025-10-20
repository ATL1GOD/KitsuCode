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

  // Método para obtener las secciones
  Future<List<SectionData>> getSections() async {
    try {
      // 1. Llama a la tabla 'secciones' de Supabase
      final response = await _client
          .from('secciones')
          .select()
          .order('etapa', ascending: true) // Ordena por etapa
          .order('seccion', ascending: true); // y luego por seccion

      // 2. Convierte la lista de JSON (List<Map<String, dynamic>>)
      //    en una lista de objetos SectionData
      final sections = response
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      return sections;
    } catch (e) {
      // Maneja el error apropiadamente
      print("Error en SectionRepository: $e");
      throw Exception('No se pudieron cargar las secciones');
    }
  }
}
