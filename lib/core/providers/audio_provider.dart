import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;
  // Usamos múltiples players para permitir solapamiento de sonidos si es necesario
  final AudioPlayer _player = AudioPlayer();

  AudioController(this.ref);

  /// Método genérico privado para reproducir
  Future<void> _play(String assetName) async {
    // 1. Leemos la configuración actual SIN escuchar cambios (read)
    //    para no reconstruir widgets innecesariamente.
    final settingsState = ref.read(settingsProvider);

    // 2. Verificamos si tenemos datos y si el sonido está activado
    if (!settingsState.hasValue || settingsState.value == null) return;
    
    final config = settingsState.value!;
    
    // Si el usuario desactivó los efectos en la BD, no hacemos nada.
    if (!config.sonidoEfectos) return;

    try {
      // 3. Configurar volumen según la preferencia del usuario
      // El volumen en audioplayers va de 0.0 a 1.0
      await _player.setVolume(config.volumenAudio.clamp(0.0, 1.0));
      
      // 4. Reproducir
      // Nota: En audioplayers v6+, AssetSource busca en 'assets/' automáticamente
      // Si tu archivo está en 'assets/audio/click.mp3', usa 'audio/click.mp3'
      if (_player.state == PlayerState.playing) {
        await _player.stop(); // Reiniciar si ya está sonando para efectos rápidos
      }
      await _player.play(AssetSource('audio/$assetName'));
      
    } catch (e) {
      // Manejo silencioso de errores de audio para no interrumpir la UX
      print('Error reproduciendo audio: $e');
    }
  }

  // --- Métodos públicos para usar en la UI ---

  Future<void> playClick() async {
    await _play('click.mp3');
  }

  Future<void> playSuccess() async {
    await _play('success.mp3');
  }

  Future<void> playError() async {
    await _play('error.mp3');
  }
  
  // Para el desbloqueo de nivel, quizás un sonido más "mágico"
  Future<void> playLevelUnlock() async {
    await _play('unlock.mp3'); 
  }
}