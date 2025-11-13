// lib/features/settings/repository/support_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider para el repositorio
final supportRepositoryProvider = Provider((ref) {
  return SupportRepository(Supabase.instance.client);
});

class SupportRepository {
  final SupabaseClient _supabase;
  SupportRepository(this._supabase);

  /// Inserta un reporte de error o sugerencia en la base de datos (tabla 'reporte_error').
  Future<void> submitReport({
    required String userId,
    required String type,
    required String description,
  }) async {
    // La columna 'fecha_reporte' tiene DEFAULT now() en tu BD, así que no se envía.
    await _supabase.from('reporte_error').insert({
      'usuario_id': userId,
      'tipo_error': type,
      'descripcion': description,
    }).select(); // Agregamos .select() al final para que devuelva algo y maneje mejor las excepciones.
  }
}