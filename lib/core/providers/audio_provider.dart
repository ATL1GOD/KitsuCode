import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;
  
  // Canal 1: Efectos de Sonido (SFX)
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  // Canal 2: Música de Fondo (BGM)
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Cache para saber qué debería estar sonando
  String? _currentMusicTrack;

  AudioController(this.ref) {
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Configuración de contexto para optimizar audio en segundo plano/interrupciones
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false, // Ahorra batería
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);
  }

  // ==========================================
  // LÓGICA DE EFECTOS (SFX)
  // ==========================================
  Future<void> _playSfx(String assetName) async {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return;
    
    final config = settingsState.value!;
    if (!config.sonidoEfectos) return;

    try {
      double volumen = config.volumenAudio.clamp(0.0, 1.0);
      await _sfxPlayer.setVolume(volumen);
      
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop();
      }
      
      await _sfxPlayer.play(AssetSource('audio/$assetName'));
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> playClick() async => await _playSfx('click.mp3');
  Future<void> playSuccess() async => await _playSfx('success.mp3');
  Future<void> playError() async => await _playSfx('error.mp3');
  Future<void> playLevelUnlock() async => await _playSfx('unlock.mp3');


  // ==========================================
  // LÓGICA DE MÚSICA DE FONDO (BGM)
  // ==========================================
  
  Future<void> playBackgroundMusic(String languageName) async {
    String trackName;
    switch (languageName.toLowerCase()) {
      case 'python': trackName = 'bgm_python.mp3'; break;
      case 'java': trackName = 'bgm_java.mp3'; break;
      case 'c': trackName = 'bgm_c.mp3'; break;
      default: trackName = 'bgm_menu.mp3'; break;
    }

    // 🔍 VERIFICACIÓN INTELIGENTE (IDEMPOTENCIA)
    // Si ya estamos tocando ESTA canción y el player está activo, NO REINICIAMOS.
    // Esto permite llamar a este método muchas veces sin causar cortes.
    if (_currentMusicTrack == trackName && _musicPlayer.state == PlayerState.playing) {
      await updateMusicVolume(); // Solo aseguramos que el volumen sea correcto
      return;
    }

    _currentMusicTrack = trackName;

    try {
      await updateMusicVolume(); 
      // Si estaba parada o era otra canción, le damos play.
      await _musicPlayer.play(AssetSource('audio/music/$trackName'));
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> updateMusicVolume() async {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return;

    double volumenUsuario = settingsState.value!.volumenAudio.clamp(0.0, 1.0);
    // Música al 60% para dejar espacio a los efectos
    double volumenFinal = volumenUsuario * 0.6; 

    await _musicPlayer.setVolume(volumenFinal);
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
    // NOTA: No limpiamos _currentMusicTrack aquí a propósito.
    // Así, si intentamos reproducir la misma canción después, el playBackgroundMusic
    // detectará que el estado NO es 'playing' y la reiniciará.
  }

  // ==========================================
  // CICLO DE VIDA
  // ==========================================
  
  Future<void> pauseMusicAppLifecycle() async {
    // Solo pausamos si realmente está sonando
    if (_musicPlayer.state == PlayerState.playing) {
      await _musicPlayer.pause();
    }
  }
  
  Future<void> resumeMusicAppLifecycle() async {
     // Intentamos reanudar
     if (_musicPlayer.state == PlayerState.paused) {
       await _musicPlayer.resume();
     }
  }

  void dispose() {
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}