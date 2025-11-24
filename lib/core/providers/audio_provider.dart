import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitsucode/features/settings/provider/settings_provider.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  return AudioController(ref);
});

class AudioController {
  final Ref ref;

  // 🔥 OPTIMIZACIÓN CRÍTICA: Pool de players precargados
  final Map<String, AudioPlayer> _sfxPlayers = {};
  final AudioPlayer _musicPlayer = AudioPlayer();

  String? _currentMusicTrack;
  bool _shouldBePlaying = false;
  Timer? _watchdogTimer;

  AudioController(this.ref) {
    // Optimización 1: Música en modo Loop
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
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    AudioPlayer.global.setAudioContext(audioContext);

    // 🔥 OPTIMIZACIÓN: Precargar todos los SFX
    _preloadSfx();

    _startWatchdog();
  }

  // 🎯 Precarga de SFX para evitar recrear MediaCodec
  Future<void> _preloadSfx() async {
    final sfxFiles = ['click.mp3', 'success.mp3', 'error.mp3', 'unlock.mp3'];

    for (final file in sfxFiles) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);

      // Precargar el archivo sin reproducir
      try {
        await player.setSource(AssetSource('audio/$file'));
        await player.setVolume(1.0);
        _sfxPlayers[file] = player;
      } catch (e) {
        // Si falla la precarga, continuar
        player.dispose();
      }
    }
  }

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
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkMusicState();
    });
  }

  Future<void> _checkMusicState() async {
    // Si el volumen es 0, no forzamos play (ahorro de batería)
    if (_getMusicVolume() <= 0) return;

    // Si la bandera dice que NO debe sonar, el watchdog se detiene aquí.
    if (!_shouldBePlaying || _currentMusicTrack == null) {
      return;
    }

    final currentState = _musicPlayer.state;
    
    // Solo intervenir si debería sonar y no lo hace
    if (currentState != PlayerState.playing) {
      try {
        if (currentState == PlayerState.paused) {
          await _musicPlayer.resume();
          await Future.delayed(const Duration(milliseconds: 150));
          
          if (_musicPlayer.state == PlayerState.playing) {
            return;
          }
        }
        await _musicPlayer.play(AssetSource('audio/music/$_currentMusicTrack'));
      } catch (e) {
        // Fallo silencioso
      }
    }
  }

  // --- SFX ---
  // 🔥 OPTIMIZACIÓN CRÍTICA: Reutilizar players precargados
  Future<void> _playSfx(String assetName) async {
    // Si efectos desactivados, salir rápido
    if (!_areSfxEnabled()) return;

    final player = _sfxPlayers[assetName];
    if (player == null) return;

    try {
      // En lugar de stop() + play() que destruye el decoder,
      // usamos seek(0) + resume() que reutiliza el decoder existente
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e) {
      // Si falla, intentar método tradicional como fallback
      try {
        await player.stop();
        await player.play(AssetSource('audio/$assetName'));
      } catch (_) {
        // Fallo silencioso
      }
    }
  }

  Future<void> playClick() async => await _playSfx('click.mp3');
  Future<void> playSuccess() async => await _playSfx('success.mp3');
  Future<void> playError() async => await _playSfx('error.mp3');
  Future<void> playLevelUnlock() async => await _playSfx('unlock.mp3');

  // --- MÚSICA ---
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

    // Si volumen es 0, pausar y no cargar nada nuevo
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

  Future<void> updateMusicVolume() async {
    final volumenDb = _getMusicVolume();
    double volumenFinal = volumenDb * 0.6; 

    if (volumenFinal <= 0) {
      if (_musicPlayer.state == PlayerState.playing) {
        await _musicPlayer.pause();
      }
    } else {
      await _musicPlayer.setVolume(volumenFinal);

      if (_shouldBePlaying && 
          _currentMusicTrack != null && 
          _musicPlayer.state != PlayerState.playing) {
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

  // 🔥 CORRECCIÓN CRÍTICA:
  // Al salir de la app, ponemos la bandera en false.
  // Así el watchdog sabe que NO debe intentar reproducir nada.
  Future<void> pauseMusicAppLifecycle() async {
    _shouldBePlaying = false; // 👈 ESTO ES LO QUE FALTABA
    
    if (_musicPlayer.state == PlayerState.playing) {
      await _musicPlayer.pause();
    }
  }

  Future<void> forceResumeMusic() async {
    if (_currentMusicTrack == null) return;
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

    // Limpiar todos los SFX players
    for (final player in _sfxPlayers.values) {
      player.dispose();
    }
    _sfxPlayers.clear();
  }
}