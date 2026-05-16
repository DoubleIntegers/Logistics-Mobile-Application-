import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AudioPlayerState { idle, loading, playing, paused, completed, error }

class AudioService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerState _state = AudioPlayerState.idle;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  String? _currentUrl;
  String? _errorMessage;

  AudioPlayerState get state => _state;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  String? get currentUrl => _currentUrl;
  String? get errorMessage => _errorMessage;

  bool get isPlaying => _state == AudioPlayerState.playing;
  bool get isPaused => _state == AudioPlayerState.paused;
  bool get isLoading => _state == AudioPlayerState.loading;
  bool get isCompleted => _state == AudioPlayerState.completed;

  double get progress {
    if (_duration == Duration.zero) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String get positionLabel => _formatDuration(_position);
  String get durationLabel => _formatDuration(_duration);

  AudioService() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _state = AudioPlayerState.playing;
        case PlayerState.paused:
          _state = AudioPlayerState.paused;
        case PlayerState.stopped:
          _state = AudioPlayerState.idle;
          _position = Duration.zero;
        case PlayerState.completed:
          _state = AudioPlayerState.completed;
          _position = Duration.zero;
        case PlayerState.disposed:
          break;
      }
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
  }

  Future<void> load(String url) async {
    try {
      _state = AudioPlayerState.loading;
      _currentUrl = url;
      _errorMessage = null;
      notifyListeners();

      await _player.setSourceUrl(url);
      _state = AudioPlayerState.idle;
      log('🎵 Audio loaded: $url');
    } catch (e) {
      _state = AudioPlayerState.error;
      _errorMessage = e.toString();
      log('❌ Audio load error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> play([String? url]) async {
    try {
      if (url != null && url != _currentUrl) {
        await load(url);
      }
      if (_state == AudioPlayerState.completed ||
          _state == AudioPlayerState.idle) {
        await _player.resume();
      } else {
        await _player.resume();
      }
    } catch (e) {
      _state = AudioPlayerState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> pause() async => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekByFraction(double fraction) async {
    final ms = (fraction * _duration.inMilliseconds).round();
    await seek(Duration(milliseconds: ms));
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}