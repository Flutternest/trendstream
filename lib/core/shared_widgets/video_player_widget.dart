import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/providers/video_player_controller_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends ConsumerWidget {
  final String videoUrl;
  final String heroTag;
  final bool showControls;
  final bool autoPlay;
  final double? aspectRatio;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isUsedInMiniPlayer;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.heroTag,
    this.showControls = false,
    this.autoPlay = false,
    this.aspectRatio,
    this.onTap,
    this.onDoubleTap,
    this.isUsedInMiniPlayer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoControllerNotifier =
        ref.watch(videoPlayerControllerProvider(videoUrl));

    if (isUsedInMiniPlayer) {
      // Initialize with muted volume only if autoPlay is false
      if (!autoPlay && videoControllerNotifier.isInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (videoControllerNotifier.volume > 0.0) {
            videoControllerNotifier.setVolume(0.0);
          }
          if (!videoControllerNotifier.isPlaying) {
            videoControllerNotifier.play();
          }
        });
      }
    }

    if (videoControllerNotifier.isLoading) {
      return Hero(
        tag: heroTag,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (videoControllerNotifier.hasError) {
      return Hero(
        tag: heroTag,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading video',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  videoControllerNotifier.errorMessage ?? 'Unknown error',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (videoControllerNotifier.isInitialized &&
        videoControllerNotifier.controller != null) {
      return GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Hero(
          tag: heroTag,
          child: AspectRatio(
            aspectRatio: aspectRatio ??
                videoControllerNotifier.controller!.value.aspectRatio,
            child: VideoPlayer(videoControllerNotifier.controller!),
          ),
        ),
      );
    }

    // Fallback loading state
    return Hero(
      tag: heroTag,
      child: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
