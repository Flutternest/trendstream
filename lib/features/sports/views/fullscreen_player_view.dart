import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/providers/video_player_controller_provider.dart';
import 'package:latest_movies/core/shared_widgets/video_player_widget.dart';

class FullScreenPlayerView extends ConsumerStatefulWidget {
  final String videoUrl;
  final String heroTag;

  const FullScreenPlayerView({
    super.key,
    required this.videoUrl,
    required this.heroTag,
  });

  @override
  ConsumerState<FullScreenPlayerView> createState() =>
      _FullScreenPlayerViewState();
}

class _FullScreenPlayerViewState extends ConsumerState<FullScreenPlayerView> {
  final FocusNode _backButtonFocus = FocusNode();
  final FocusNode _seekBarFocus = FocusNode();
  final FocusNode _playPauseFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Hide system UI for full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Auto-play video when entering full screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoPlayerControllerProvider(widget.videoUrl).notifier).play();
      // Focus on play/pause button initially
      Future.delayed(const Duration(milliseconds: 100), () {
        _playPauseFocus.requestFocus();
        log('Initial focus set to play/pause button');
      });
    });
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Dispose focus nodes
    _backButtonFocus.dispose();
    _seekBarFocus.dispose();
    _playPauseFocus.dispose();

    // Mute video when leaving full screen
    ref.read(videoPlayerControllerProvider(widget.videoUrl).notifier).mute();

    super.dispose();
  }

  void _togglePlayPause() {
    ref
        .read(videoPlayerControllerProvider(widget.videoUrl).notifier)
        .togglePlayPause();
  }

  void _seekTo(Duration position) {
    ref
        .read(videoPlayerControllerProvider(widget.videoUrl).notifier)
        .seekTo(position);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      log('Key pressed: ${event.logicalKey}');
      log('Back button focus: ${_backButtonFocus.hasFocus}');
      log('Seek bar focus: ${_seekBarFocus.hasFocus}');
      log('Play pause focus: ${_playPauseFocus.hasFocus}');

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_seekBarFocus.hasFocus) {
            log('Moving focus from seek bar to back button');
            _backButtonFocus.requestFocus();
          } else if (_playPauseFocus.hasFocus) {
            log('Moving focus from play/pause to seek bar');
            _seekBarFocus.requestFocus();
          } else if (!_backButtonFocus.hasFocus &&
              !_seekBarFocus.hasFocus &&
              !_playPauseFocus.hasFocus) {
            // If no focus, start with play/pause
            log('No focus detected, setting focus to play/pause');
            _playPauseFocus.requestFocus();
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (_backButtonFocus.hasFocus) {
            log('Moving focus from back button to seek bar');
            _seekBarFocus.requestFocus();
          } else if (_seekBarFocus.hasFocus) {
            log('Moving focus from seek bar to play/pause');
            _playPauseFocus.requestFocus();
          } else if (!_backButtonFocus.hasFocus &&
              !_seekBarFocus.hasFocus &&
              !_playPauseFocus.hasFocus) {
            // If no focus, start with play/pause
            log('No focus detected, setting focus to play/pause');
            _playPauseFocus.requestFocus();
          }
          break;
        case LogicalKeyboardKey.arrowLeft:
          if (_seekBarFocus.hasFocus) {
            // Handle seek backward
            final controller =
                ref.read(videoPlayerControllerProvider(widget.videoUrl));
            controller.whenData((ctrl) {
              final newPosition =
                  ctrl.value.position - const Duration(seconds: 10);
              _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
            });
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (_seekBarFocus.hasFocus) {
            // Handle seek forward
            final controller =
                ref.read(videoPlayerControllerProvider(widget.videoUrl));
            controller.whenData((ctrl) {
              final newPosition =
                  ctrl.value.position + const Duration(seconds: 10);
              _seekTo(newPosition > ctrl.value.duration
                  ? ctrl.value.duration
                  : newPosition);
            });
          }
          break;
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          if (_backButtonFocus.hasFocus) {
            Navigator.of(context).pop();
          } else if (_playPauseFocus.hasFocus) {
            _togglePlayPause();
          }
          break;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final videoControllerAsync =
        ref.watch(videoPlayerControllerProvider(widget.videoUrl));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        onKeyEvent: (node, event) => _handleKeyEvent(event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored,
        child: Stack(
          children: [
            // Full screen video player with Hero animation
            Positioned.fill(
              child: VideoPlayerWidget(
                videoUrl: widget.videoUrl,
                heroTag: widget.heroTag,
                showControls: false,
                autoPlay: true,
              ),
            ),

            // Top left back button
            Positioned(
              top: 40,
              left: 20,
              child: Focus(
                focusNode: _backButtonFocus,
                onFocusChange: (hasFocus) {
                  log('Back button focus changed: $hasFocus');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: _backButtonFocus.hasFocus
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seek bar
                  Focus(
                    focusNode: _seekBarFocus,
                    onFocusChange: (hasFocus) {
                      log('Seek bar focus changed: $hasFocus');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: _seekBarFocus.hasFocus
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: videoControllerAsync.when(
                        data: (controller) => Row(
                          children: [
                            Text(
                              _formatDuration(controller.value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor:
                                      Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.2),
                                  trackHeight: 3.0,
                                ),
                                child: Slider(
                                  value:
                                      controller.value.duration.inMilliseconds >
                                              0
                                          ? controller.value.position
                                                  .inMilliseconds /
                                              controller
                                                  .value.duration.inMilliseconds
                                          : 0.0,
                                  onChanged: (value) {
                                    final position = Duration(
                                      milliseconds: (value *
                                              controller.value.duration
                                                  .inMilliseconds)
                                          .round(),
                                    );
                                    _seekTo(position);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(controller.value.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Play/Pause button
                  Focus(
                    focusNode: _playPauseFocus,
                    onFocusChange: (hasFocus) {
                      log('Play/Pause focus changed: $hasFocus');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: _playPauseFocus.hasFocus
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: videoControllerAsync.when(
                        data: (controller) => IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
