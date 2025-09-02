import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

// Provider for video player controller with URL as family parameter
final videoPlayerControllerProvider = StateNotifierProvider.family<
    VideoPlayerControllerNotifier,
    AsyncValue<VideoPlayerController>,
    String>((ref, videoUrl) {
  final notifier = VideoPlayerControllerNotifier(videoUrl);

  // Auto-dispose when the provider is no longer used
  ref.onDispose(() {
    notifier.dispose();
  });

  return notifier;
});

class VideoPlayerControllerNotifier
    extends StateNotifier<AsyncValue<VideoPlayerController>> {
  final String videoUrl;
  VideoPlayerController? _controller;

  VideoPlayerControllerNotifier(this.videoUrl)
      : super(const AsyncValue.loading()) {
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      state = const AsyncValue.loading();

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();

      state = AsyncValue.data(_controller!);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> play() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
    }
  }

  Future<void> pause() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.pause();
    }
  }

  Future<void> togglePlayPause() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.seekTo(position);
    }
  }

  Future<void> setVolume(double volume) async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(volume);
    }
  }

  Future<void> mute() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(0.0);
    }
  }

  Future<void> unmute() async {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      await controller.setVolume(1.0);
    }
  }

  bool get isMuted {
    final controller = _controller;
    return controller?.value.volume == 0.0;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
