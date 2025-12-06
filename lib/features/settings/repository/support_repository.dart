import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supportRepositoryProvider = Provider((ref) {
  return SupportRepository(Supabase.instance.client);
});

class SupportRepository {
  final SupabaseClient _supabase;
  SupportRepository(this._supabase);

  Future<void> submitReport({
    required String userId,
    required String type,
    required String description,
  }) async {
    await _supabase.from('reporte_error').insert({
      'usuario_id': userId,
      'tipo_error': type,
      'descripcion': description,
    }).select();
  }
}
