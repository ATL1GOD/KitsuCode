import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitsucode/features/home/model/home_model.dart';

class HomeMapData {
  final List<SectionData> sections;
  final Set<int> completedLevelIds;

  HomeMapData({required this.sections, required this.completedLevelIds});
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SectionRepository(client);
});

class SectionRepository {
  final SupabaseClient _client;
  SectionRepository(this._client);

  Future<HomeMapData> getHomeMapData(int languageId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception("Usuario no autenticado");
    }

    try {
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
          .order('orden', ascending: true)
          .order('orden', referencedTable: 'niveles', ascending: true);

      final sections = sectionsResponse
          .map<SectionData>((json) => SectionData.fromJson(json))
          .toList();

      final progressResponse = await _client
          .from('progreso_usuario')
          .select('id_nivel')
          .eq('id_usuario', currentUserId);

      final completedLevelIds = progressResponse
          .map<int>((json) => json['id_nivel'] as int)
          .toSet();

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
