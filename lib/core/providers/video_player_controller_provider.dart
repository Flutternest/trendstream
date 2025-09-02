import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

// Provider for video player controller with URL as family parameter
final videoPlayerControllerProvider =
    ChangeNotifierProvider.family<VideoPlayerControllerNotifier, String>(
        (ref, videoUrl) {
  final notifier = VideoPlayerControllerNotifier(videoUrl);

  // Auto-dispose when the provider is no longer used
  ref.onDispose(() {
    notifier.dispose();
  });

  return notifier;
});

class VideoPlayerControllerNotifier extends ChangeNotifier {
  final String videoUrl;
  VideoPlayerController? _controller;

  // State variables
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.0; // Start muted
  bool _isMuted = true;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  VideoPlayerController? get controller => _controller;

  VideoPlayerControllerNotifier(this.videoUrl) {
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();

      print(
          'VideoPlayerController: Initializing controller for URL: $videoUrl');

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();

      // Set up listener for video controller updates
      _controller!.addListener(_videoControllerListener);

      _isInitialized = true;
      _isLoading = false;
      _duration = _controller!.value.duration;
      _position = _controller!.value.position;
      _isPlaying = _controller!.value.isPlaying;
      _volume = _controller!.value.volume;
      _isMuted = _volume == 0.0;

      print('VideoPlayerController: Controller initialized successfully');
      notifyListeners();
    } catch (error, _) {
      print('VideoPlayerController: Error initializing controller: $error');
      _isLoading = false;
      _hasError = true;
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _videoControllerListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final value = _controller!.value;

      // Update state variables
      _duration = value.duration;
      _position = value.position;
      _isPlaying = value.isPlaying;
      _volume = value.volume;
      _isMuted = _volume == 0.0;

      // Notify listeners of changes
      notifyListeners();
    }
  }

  Future<void> play() async {
    if (_controller != null && _isInitialized) {
      await _controller!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_controller != null && _isInitialized) {
      print('VideoPlayerController: togglePlayPause - isPlaying: $_isPlaying');
      if (_isPlaying) {
        await _controller!.pause();
        _isPlaying = false;
        print('VideoPlayerController: Paused video');
      } else {
        await _controller!.play();
        _isPlaying = true;
        print('VideoPlayerController: Playing video');
      }
      notifyListeners();
    } else {
      print(
          'VideoPlayerController: togglePlayPause - controller not initialized');
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_controller != null && _isInitialized) {
      print('VideoPlayerController: seekTo - position: $position');
      await _controller!.seekTo(position);
      _position = position;
      print('VideoPlayerController: Seek completed');
      notifyListeners();
    } else {
      print('VideoPlayerController: seekTo - controller not initialized');
    }
  }

  Future<void> setVolume(double volume) async {
    if (_controller != null && _isInitialized) {
      await _controller!.setVolume(volume);
      _volume = volume;
      _isMuted = volume == 0.0;
      notifyListeners();
    }
  }

  Future<void> mute() async {
    if (_controller != null && _isInitialized) {
      await _controller!.setVolume(0.0);
      _volume = 0.0;
      _isMuted = true;
      notifyListeners();
    }
  }

  Future<void> unmute() async {
    if (_controller != null && _isInitialized) {
      await _controller!.setVolume(1.0);
      _volume = 1.0;
      _isMuted = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoControllerListener);
    _controller?.dispose();
    super.dispose();
  }
}
