import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;

  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _errorPlayer = AudioPlayer();
  final AudioPlayer _unlockPlayer = AudioPlayer();

  final AudioPlayer _musicPlayer = AudioPlayer();

  String? _currentMusicTrack;
  bool _shouldBePlaying = false;
  Timer? _watchdogTimer;

  AudioController(this.ref) {
    _initAudioContext();

    Future.delayed(Duration(milliseconds: 100), () => _preloadSfx());
    _startWatchdog();
  }

  Future<void> _initAudioContext() async {
    try {
      final AudioContext audioContext = AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: <AVAudioSessionOptions>{},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,

          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      );

      await AudioPlayer.global.setAudioContext(audioContext);

      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      if (kDebugMode) {
        print("Error configurando contexto de audio: $e");
      }
    }
  }

  Future<void> _preloadSfx() async {
    await _setupSfxPlayer(_clickPlayer, 'click.wav');
    await _setupSfxPlayer(_successPlayer, 'success.wav');
    await _setupSfxPlayer(_errorPlayer, 'error.wav');
    await _setupSfxPlayer(_unlockPlayer, 'unlock.wav');
  }

  Future<void> _setupSfxPlayer(AudioPlayer player, String file) async {
    await player.setReleaseMode(ReleaseMode.stop);

    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setSource(AssetSource('audio/$file'));
  }

  Future<void> _playSfx(AudioPlayer player) async {
    if (!_areSfxEnabled()) return;

    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      if (kDebugMode) {
        print("Error SFX: $e");
      }
    }
  }

  Future<void> playClick() async => await _playSfx(_clickPlayer);
  Future<void> playSuccess() async => await _playSfx(_successPlayer);
  Future<void> playError() async => await _playSfx(_errorPlayer);
  Future<void> playLevelUnlock() async => await _playSfx(_unlockPlayer);

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

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _checkMusicState(),
    );
  }

  Future<void> _checkMusicState() async {
    if (_getMusicVolume() <= 0) return;
    if (!_shouldBePlaying || _currentMusicTrack == null) return;

    if (_musicPlayer.state != PlayerState.playing) {
      try {
        if (_musicPlayer.state == PlayerState.paused) {
          await _musicPlayer.resume();
        } else {
          await _musicPlayer.play(
            AssetSource('audio/music/$_currentMusicTrack'),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> playBackgroundMusic(String languageName) async {
    String trackName;
    switch (languageName.toLowerCase().trim()) {
      case 'python':
        trackName = 'bgm_python.mp3';
        break;
      case 'java':
        trackName = 'bgm_java.mp3';
        break;
      case 'c':
        trackName = 'bgm_c.mp3';
        break;
      default:
        trackName = 'bgm_menu.mp3';
        break;
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
      if (_shouldBePlaying &&
          _currentMusicTrack != null &&
          _musicPlayer.state != PlayerState.playing) {
        if (_musicPlayer.state == PlayerState.paused) {
          await _musicPlayer.resume();
        } else {
          await _musicPlayer.play(
            AssetSource('audio/music/$_currentMusicTrack'),
          );
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
