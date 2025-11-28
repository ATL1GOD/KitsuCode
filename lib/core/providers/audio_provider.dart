import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;

  // Players para efectos
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _unlockPlayer = AudioPlayer();

  // Player para música
  final AudioPlayer _musicPlayer = AudioPlayer();

  String? _currentMusicTrack;
  bool _shouldBePlaying = false;
  Timer? _watchdogTimer;

  AudioController(this.ref) {
    _initAudioContext();
    // No llamamos a _preloadSfx aquí inmediatamente para dar tiempo al contexto global
    Future.delayed(Duration(milliseconds: 100), () => _preloadSfx());
    _startWatchdog();
  }

  // 1. CORRECCIÓN DEL CRASH (CRÍTICO)
  Future<void> _initAudioContext() async {
    try {
      final AudioContext audioContext = AudioContext(
        iOS: AudioContextIOS(
          // 'ambient' ya implica mezcla. No pongas 'mixWithOthers' aquí o crashea.
          category: AVAudioSessionCategory.ambient,
          options: <AVAudioSessionOptions>{}, 
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          // Music + Game + None = La combinación ganadora para que no se corte
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, 
        ),
      );
      
      await AudioPlayer.global.setAudioContext(audioContext);
      
      // Configuramos el player de música
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer); // Música siempre en MediaPlayer
    } catch (e) {
      print("Error configurando contexto de audio: $e");
    }
  }

  Future<void> _preloadSfx() async {
    // Configuramos los players de efectos
    await _setupSfxPlayer(_clickPlayer, 'click.wav');
    await _setupSfxPlayer(_successPlayer, 'success.wav');
    await _setupSfxPlayer(_errorPlayer, 'error.wav');
    await _setupSfxPlayer(_unlockPlayer, 'unlock.wav');
  }

  Future<void> _setupSfxPlayer(AudioPlayer player, String file) async {
    // ReleaseMode.stop es vital para que no "muera" después de sonar una vez
    await player.setReleaseMode(ReleaseMode.stop);
    // LowLatency usa SoundPool (Cero Lag)
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setSource(AssetSource('audio/$file'));
  }

  // --- REPRODUCCIÓN EFECTOS ---
  Future<void> _playSfx(AudioPlayer player) async {
    if (!_areSfxEnabled()) return;
    
    try {
      // stop() reinicia el cabezal a 0. Vital para LowLatency.
      await player.stop();
      await player.resume();
    } catch (e) {
      print("Error SFX: $e");
    }
  }

  // API Pública
  Future<void> playClick() async => await _playSfx(_clickPlayer);
  Future<void> playSuccess() async => await _playSfx(_successPlayer);
  Future<void> playError() async => await _playSfx(_errorPlayer);
  Future<void> playLevelUnlock() async => await _playSfx(_unlockPlayer);

  // --- HELPERS ---
  double _getMusicVolume() {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return 1.0;
    return settingsState.value!.volumenAudio.clamp(0.0, 1.0);
  }

  bool _areSfxEnabled() {
    final settingsState = ref.read(settingsProvider);
    if (!settingsState.hasValue || settingsState.value == null) return true;
    return settingsState.value!.sonidoEfectos;
  }

  // --- WATCHDOG ---
  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _checkMusicState());
  }

  Future<void> _checkMusicState() async {
    if (_getMusicVolume() <= 0) return;
    if (!_shouldBePlaying || _currentMusicTrack == null) return;

    if (_musicPlayer.state != PlayerState.playing) {
      try {
        if (_musicPlayer.state == PlayerState.paused) {
          await _musicPlayer.resume();
        } else {
          await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
        }
      } catch (_) {}
    }
  }

  // --- MÚSICA DE FONDO ---
  Future<void> playBackgroundMusic(String languageName) async {
    String trackName;
    switch (languageName.toLowerCase().trim()) {
      case 'python': trackName = 'bgm_python.mp3'; break;
      case 'java': trackName = 'bgm_java.mp3'; break;
      case 'c': trackName = 'bgm_c.mp3'; break;
      default: trackName = 'bgm_menu.mp3'; break;
    }

    _shouldBePlaying = true;

    if (_currentMusicTrack == trackName) {
      await updateMusicVolume();
      return;
    }

    _currentMusicTrack = trackName;

    if (_getMusicVolume() <= 0) {
      if (_musicPlayer.state == PlayerState.playing) await _musicPlayer.pause();
      return;
    }

    try {
      await updateMusicVolume();
      if (_musicPlayer.state == PlayerState.playing) await _musicPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 50));
      await _musicPlayer.play(AssetSource('audio/music/$trackName'));
    } catch (_) {
      _shouldBePlaying = false;
    }
  }

  Future<void> updateMusicVolume() async {
    final volumenDb = _getMusicVolume();
    double volumenFinal = volumenDb * 0.6; 

    if (volumenFinal <= 0) {
      if (_musicPlayer.state == PlayerState.playing) await _musicPlayer.pause();
    } else {
      await _musicPlayer.setVolume(volumenFinal);
      if (_shouldBePlaying && _currentMusicTrack != null && _musicPlayer.state != PlayerState.playing) {
         if (_musicPlayer.state == PlayerState.paused) {
           await _musicPlayer.resume();
         } else {
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
    _shouldBePlaying = false;
    if (_musicPlayer.state == PlayerState.playing) await _musicPlayer.pause();
  }

  Future<void> forceResumeMusic() async {
    if (_currentMusicTrack == null || _getMusicVolume() <= 0) return;
    _shouldBePlaying = true;
    try {
      if (_musicPlayer.state == PlayerState.paused) {
        await _musicPlayer.resume();
      } else {
        await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
      }
      await updateMusicVolume();
    } catch (_) {}
  }

  void dispose() {
    _watchdogTimer?.cancel();
    _clickPlayer.dispose();
    _successPlayer.dispose();
    _errorPlayer.dispose();
    _unlockPlayer.dispose();
    _musicPlayer.dispose();
  }
}