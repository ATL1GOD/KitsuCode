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
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    
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
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    );
    AudioPlayer.global.setAudioContext(audioContext);

    _startWatchdog();
  }

  // Watchdog timer que verifica cada 500ms
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkMusicState();
    });
  }

  // Verifica si la música debería estar sonando pero no lo está
  Future<void> _checkMusicState() async {
    if (!_shouldBePlaying || _currentMusicTrack == null) {
      return;
    }

    final currentState = _musicPlayer.state;
    
    // Solo intervenir si NO está sonando Y debería estar sonando
    if (currentState != PlayerState.playing) {
      try {
        // Primero intentar resume
        if (currentState == PlayerState.paused) {
          await _musicPlayer.resume();
          await Future.delayed(const Duration(milliseconds: 150));
          
          if (_musicPlayer.state == PlayerState.playing) {
            return;
          }
        }
        
        // Si resume falló o no estaba pausado, hacer play completo
        await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
        
      } catch (e) {
        // Fallo silencioso
      }
    }
  }

  // ==========================================
  // EFECTOS DE SONIDO (SFX)
  // ==========================================
  
  Future<void> _playSfx(String assetName) async {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return;
    
    if (!settingsState.value!.sonidoEfectos) return;

    try {
      double volumen = settingsState.value!.volumenAudio.clamp(0.0, 1.0);
      await _sfxPlayer.setVolume(volumen);
      
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
  // ==========================================
  
  Future<void> playBackgroundMusic(String languageName) async {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) {
      return;
    }

    String trackName;
    switch (languageName.toLowerCase().trim()) {
      case 'python': trackName = 'bgm_python.mp3'; break;
      case 'java': trackName = 'bgm_java.mp3'; break;
      case 'c': trackName = 'bgm_c.mp3'; break;
      default: trackName = 'bgm_menu.mp3'; break;
    }

    _shouldBePlaying = true;

    // CASO 1: Ya está sonando la canción correcta
    if (_currentMusicTrack == trackName && _musicPlayer.state == PlayerState.playing) {
      await updateMusicVolume();
      return;
    }

    // CASO 2: Misma canción pero pausada
    if (_currentMusicTrack == trackName && _musicPlayer.state == PlayerState.paused) {
      try {
        await updateMusicVolume();
        await _musicPlayer.resume();
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (_musicPlayer.state == PlayerState.playing) {
          return;
        }
      } catch (e) {
        // Fallo silencioso, intentar play completo abajo
      }
    }

    // CASO 3: Nueva canción o resume falló
    _currentMusicTrack = trackName;

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

  Future<void> updateMusicVolume() async {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return;

    double volumenUsuario = settingsState.value!.volumenAudio.clamp(0.0, 1.0);
    double volumenFinal = volumenUsuario * 0.6;

    await _musicPlayer.setVolume(volumenFinal);
  }

  Future<void> stopMusic() async {
    _shouldBePlaying = false;
    await _musicPlayer.pause();
  }

  Future<void> pauseMusicAppLifecycle() async {
    if (_musicPlayer.state == PlayerState.playing) {
      _shouldBePlaying = false;
      await _musicPlayer.pause();
    }
  }

  // Método público para forzar la reanudación (usado por watchdog/MusicManager)
  Future<void> forceResumeMusic() async {
    if (_currentMusicTrack == null) {
      return;
    }

    _shouldBePlaying = true;

    try {
      final currentState = _musicPlayer.state;

      // Intentar resume primero
      if (currentState == PlayerState.paused) {
        await _musicPlayer.resume();
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (_musicPlayer.state == PlayerState.playing) {
          await updateMusicVolume();
          return;
        }
      }

      // Si resume no funcionó o no estaba pausado, hacer play completo
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