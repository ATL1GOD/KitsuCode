import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;
  
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  String? _currentMusicTrack;
  bool _shouldBePlaying = false;
  Timer? _watchdogTimer;

  AudioController(this.ref) {
    // Optimización 1: Música en modo Loop
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    
    // Optimización 2: SFX en modo LowLatency (Ideal para sonidos cortos)
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    
    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none, // 🔥 CLAVE: Evita que el SFX pause la música
      ),
    );
    
    AudioPlayer.global.setAudioContext(audioContext);

    _startWatchdog();
  }

  // --- HELPERS PRIVADOS PARA LEER SETTINGS ---

  // Obtiene el volumen de la música (0.0 a 1.0)
  double _getMusicVolume() {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return 1.0;
    return settingsState.value!.volumenAudio.clamp(0.0, 1.0);
  }

  // Obtiene si los efectos están activos (true/false)
  bool _areSfxEnabled() {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return true;
    return settingsState.value!.sonidoEfectos;
  }

  // --- WATCHDOG ---

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkMusicState();
    });
  }

  Future<void> _checkMusicState() async {
    // 🔥 1. Si el volumen de música es 0, no forzamos play (ahorro de batería)
    if (_getMusicVolume() <= 0) return;

    if (!_shouldBePlaying || _currentMusicTrack == null) {
      return;
    }

    final currentState = _musicPlayer.state;
    
    // 🔥 2. Solo intervenir si debería sonar y no lo hace
    if (currentState != PlayerState.playing) {
      try {
        if (currentState == PlayerState.paused) {
          await _musicPlayer.resume();
          await Future.delayed(const Duration(milliseconds: 150));
          
          if (_musicPlayer.state == PlayerState.playing) {
            return;
          }
        }
        // Si resume falló, play completo
        await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
      } catch (e) {
        // Fallo silencioso
      }
    }
  }

  // ==========================================
  // EFECTOS DE SONIDO (SFX)
  // Controlado por: sonido_efectos (Boolean)
  // ==========================================
  
  Future<void> _playSfx(String assetName) async {
    // 🔥 OPTIMIZACIÓN: Si los efectos están desactivados, salimos inmediatamente.
    // No cargamos archivos ni usamos el reproductor.
    if (!_areSfxEnabled()) return;

    try {
      // Usamos volumen 1.0 fijo para efectos (independiente de la música)
      await _sfxPlayer.setVolume(1.0);
      
      if (_sfxPlayer.state == PlayerState.playing) {
        await _sfxPlayer.stop();
      }
      await _sfxPlayer.play(AssetSource('audio/$assetName'));
    } catch (e) {
      // Fallo silencioso
    }
  }

  Future<void> playClick() async => await _playSfx('click.mp3');
  Future<void> playSuccess() async => await _playSfx('success.mp3');
  Future<void> playError() async => await _playSfx('error.mp3');
  Future<void> playLevelUnlock() async => await _playSfx('unlock.mp3');

  // ==========================================
  // MÚSICA DE FONDO (BGM)
  // Controlado por: volumen_audio (Numeric)
  // ==========================================
  
  Future<void> playBackgroundMusic(String languageName) async {
    String trackName;
    switch (languageName.toLowerCase().trim()) {
      case 'python': trackName = 'bgm_python.mp3'; break;
      case 'java': trackName = 'bgm_java.mp3'; break;
      case 'c': trackName = 'bgm_c.mp3'; break;
      default: trackName = 'bgm_menu.mp3'; break;
    }

    _shouldBePlaying = true;

    // Si ya es la canción correcta
    if (_currentMusicTrack == trackName) {
      await updateMusicVolume();
      return;
    }

    _currentMusicTrack = trackName;

    // 🔥 OPTIMIZACIÓN CRÍTICA:
    // Si el volumen de música es 0, pausamos y NO cargamos nada nuevo.
    // Evita decodificar audio si no se va a escuchar.
    if (_getMusicVolume() <= 0) {
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.pause();
      }
      return;
    }

    try {
      await updateMusicVolume();
      
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.stop();
      }
      
      await Future.delayed(const Duration(milliseconds: 50));
      await _musicPlayer.play(AssetSource('audio/music/$trackName'));
      
    } catch (e) {
      _currentMusicTrack = null;
      _shouldBePlaying = false;
    }
  }

  /// Se llama desde Settings cuando el usuario mueve el slider de volumen
  Future<void> updateMusicVolume() async {
    // Obtenemos volumen crudo de la BD (0.0 a 1.0)
    final volumenDb = _getMusicVolume();
    
    // Aplicamos un factor de reducción suave (0.6) para que no sature
    double volumenFinal = volumenDb * 0.6; 

    // 🔥 LÓGICA INTELIGENTE DE PAUSA/PLAY
    if (volumenFinal <= 0) {
      // CASO A: Volumen es 0 -> Pausamos para ahorrar batería
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.pause();
      }
    } else {
      // CASO B: Volumen > 0 -> Aplicamos volumen
      await _musicPlayer.setVolume(volumenFinal);

      // Si debería estar sonando (_shouldBePlaying) pero estaba pausada 
      // (probablemente porque el volumen era 0 antes), la reanudamos sola.
      if (_shouldBePlaying && 
          _currentMusicTrack != null && 
          _musicPlayer.state != PlayerState.playing) {
        
        if (_musicPlayer.state == PlayerState.paused) {
           await _musicPlayer.resume();
        } else {
           // Si estaba stopped, play completo
           await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
        }
      }
    }
  }

  Future<void> stopMusic() async {
    _shouldBePlaying = false;
    await _musicPlayer.pause();
  }

  Future<void> pauseMusicAppLifecycle() async {
    if (_musicPlayer.state == PlayerState.playing) {
      // No cambiamos _shouldBePlaying a false, solo pausamos el hardware
      await _musicPlayer.pause();
    }
  }

  // Método para forzar reanudación (si el sistema lo mató)
  Future<void> forceResumeMusic() async {
    if (_currentMusicTrack == null) return;
    // Si el volumen es 0, no tiene sentido forzar nada
    if (_getMusicVolume() <= 0) return; 

    _shouldBePlaying = true;

    try {
      final currentState = _musicPlayer.state;

      if (currentState == PlayerState.paused) {
        await _musicPlayer.resume();
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (_musicPlayer.state == PlayerState.playing) {
          await updateMusicVolume();
          return;
        }
      }

      await updateMusicVolume();
      await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
      
    } catch (e) {
      // Fallo silencioso
    }
  }

  void dispose() {
    _watchdogTimer?.cancel();
    _shouldBePlaying = false;
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
  }
}