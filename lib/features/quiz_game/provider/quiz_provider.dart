import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asume que tienes una instancia de Supabase client
// (Probablemente la defines en tu main.dart)
final supabase = Supabase.instance.client;

// Este proveedor tomará el ID de la sección y devolverá la lista 'mydata' formateada
final quizProvider = FutureProvider.family<List, String>((
  ref,
  seccionId,
) async {
  // 1. Obtener el ID del reto para esta sección
  final retoResponse = await supabase
      .from('retos_quiz')
      .select('id')
      .eq('seccion_id', seccionId)
      .single(); // Asumimos un quiz por sección

  if (retoResponse.isEmpty) {
    throw Exception('No se encontró un reto para esta sección.');
  }

  final retoId = retoResponse['id'];

  // 2. Obtener todas las preguntas para ese reto
  final preguntasResponse = await supabase
      .from('preguntas_quiz')
      .select('pregunta_key, pregunta_texto, opciones, respuesta_correcta')
      .eq('reto_id', retoId);

  if (preguntasResponse.isEmpty) {
    throw Exception('No se encontraron preguntas para este reto.');
  }

  // 3. Transformar los datos de Supabase al formato que 'QuizPage' espera
  // mydata[0] = Mapa de Preguntas { "1": "Texto...", "2": "Texto..." }
  // mydata[1] = Mapa de Opciones { "1": {"a": "...", "b": "..."}, "2": ... }
  // mydata[2] = Mapa de Respuestas { "1": "Respuesta...", "2": "Respuesta..." }

  final Map<String, String> mapaPreguntas = {};
  final Map<String, Map<String, dynamic>> mapaOpciones = {};
  final Map<String, String> mapaRespuestas = {};

  for (var pregunta in preguntasResponse) {
    final key = pregunta['pregunta_key'] as String; // "1", "2", etc.

    mapaPreguntas[key] = pregunta['pregunta_texto'] as String;
    mapaRespuestas[key] = pregunta['respuesta_correcta'] as String;

    // Supabase devuelve el JSON como un Map<String, dynamic>
    mapaOpciones[key] = Map<String, dynamic>.from(pregunta['opciones']);
  }

  // Devuelve la lista en el formato exacto que QuizPage espera
  return [mapaPreguntas, mapaOpciones, mapaRespuestas];
});
