import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/providers/video_player_controller_provider.dart';
import 'package:latest_movies/core/shared_widgets/video_player_widget.dart';

class FullScreenPlayerView extends HookConsumerWidget {
  final String videoUrl;
  final String heroTag;

  const FullScreenPlayerView({
    super.key,
    required this.videoUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Focus nodes for the three controls
    final backButtonFocus = useMemoized(() => FocusNode());
    final seekBarFocus = useMemoized(() => FocusNode());
    final playPauseFocus = useMemoized(() => FocusNode());

    // Focus management state
    final currentFocusedIndex =
        useState(2); // Start with play/pause button (index 2)
    final isFocused = useState(false);
    final isNavigatingBack = useState(false);

    // List of focus nodes for easy access
    final focusNodes = [backButtonFocus, seekBarFocus, playPauseFocus];

    // Initialize system UI and video
    useEffect(() {
      // Hide system UI for full screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      // Auto-play video when entering full screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          playPauseFocus.requestFocus();
          isFocused.value = true;
          log('Initial focus set to play/pause button');
          ref.read(videoPlayerControllerProvider(videoUrl).notifier).play();
          ref.read(videoPlayerControllerProvider(videoUrl).notifier).unmute();
        });
      });

      // Cleanup function
      return () {
        log('Cleaning up full screen player view');
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      };
    }, const []);

    // Helper methods
    void togglePlayPause() {
      log('Toggle play/pause called');
      ref
          .read(videoPlayerControllerProvider(videoUrl).notifier)
          .togglePlayPause();
    }

    void seekTo(Duration position) {
      log('Seek to called: $position');
      ref
          .read(videoPlayerControllerProvider(videoUrl).notifier)
          .seekTo(position);
    }

    void handleBackNavigation() {
      log('Back navigation called');
      isFocused.value = false;
      isNavigatingBack.value = true;
      ref.read(videoPlayerControllerProvider(videoUrl).notifier).mute();
      // Use a small delay to prevent the mini player from receiving the same key event
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    // Handle keyboard navigation
    final handleKeyPress = useCallback(
      (KeyEvent event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          log('Key pressed: ${event.logicalKey}');
          log('Current focused index: ${currentFocusedIndex.value}');
          log('Is focused: ${isFocused.value}');

          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              isFocused.value = true;
              final newIndex = currentFocusedIndex.value - 1;
              if (newIndex >= 0) {
                currentFocusedIndex.value = newIndex;
                focusNodes[newIndex].requestFocus();
                return true;
              }
              isFocused.value = false;
              return false;

            case LogicalKeyboardKey.arrowDown:
              isFocused.value = true;
              final newIndex = currentFocusedIndex.value + 1;
              if (newIndex < focusNodes.length) {
                currentFocusedIndex.value = newIndex;
                focusNodes[newIndex].requestFocus();
                return true;
              }
              isFocused.value = false;
              return false;

            case LogicalKeyboardKey.arrowLeft:
              if (currentFocusedIndex.value == 1) {
                // Seek bar is focused
                // Handle seek backward
                final notifier =
                    ref.read(videoPlayerControllerProvider(videoUrl));
                if (notifier.isInitialized) {
                  final newPosition =
                      notifier.position - const Duration(seconds: 10);
                  seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                }
                return true;
              }
              return false;

            case LogicalKeyboardKey.arrowRight:
              if (currentFocusedIndex.value == 1) {
                // Seek bar is focused
                // Handle seek forward
                final notifier =
                    ref.read(videoPlayerControllerProvider(videoUrl));
                if (notifier.isInitialized) {
                  final newPosition =
                      notifier.position + const Duration(seconds: 10);
                  seekTo(newPosition > notifier.duration
                      ? notifier.duration
                      : newPosition);
                }
                return true;
              }
              return false;

            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
              if (currentFocusedIndex.value == 0 && !isNavigatingBack.value) {
                // Back button
                handleBackNavigation();
                return true;
              } else if (currentFocusedIndex.value == 2) {
                // Play/Pause button
                togglePlayPause();
                return true;
              }
              return false;
          }
        }
        return false;
      },
      [
        currentFocusedIndex.value,
        isFocused.value,
        isNavigatingBack.value,
        focusNodes
      ],
    );

    // Set focus to current focused index when section becomes focused
    useEffect(() {
      if (isFocused.value && currentFocusedIndex.value < focusNodes.length) {
        Future.microtask(() {
          focusNodes[currentFocusedIndex.value].requestFocus();
        });
      }
      return null;
    }, [isFocused.value, currentFocusedIndex.value]);

    final videoControllerNotifier =
        ref.watch(videoPlayerControllerProvider(videoUrl));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        onKeyEvent: (node, event) => handleKeyPress(event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored,
        child: Stack(
          children: [
            // Full screen video player with Hero animation
            Positioned.fill(
              child: VideoPlayerWidget(
                videoUrl: videoUrl,
                heroTag: heroTag,
                showControls: false,
                autoPlay: true,
              ),
            ),

            // Top left back button
            Positioned(
              top: 40,
              left: 20,
              child: Focus(
                focusNode: backButtonFocus,
                child: Builder(builder: (context) {
                  final hasFocus =
                      isFocused.value && currentFocusedIndex.value == 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: hasFocus
                          ? Border.all(
                              width: 4,
                              color: kPrimaryAccentColor,
                            )
                          : null,
                    ),
                    child: IconButton(
                      onPressed:
                          isNavigatingBack.value ? null : handleBackNavigation,
                      icon: Icon(
                        Icons.arrow_back,
                        color: hasFocus ? Colors.white : Colors.grey[700],
                        size: 28,
                      ),
                    ),
                  );
                }),
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
                    focusNode: seekBarFocus,
                    child: Builder(builder: (context) {
                      final hasFocus =
                          isFocused.value && currentFocusedIndex.value == 1;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: hasFocus
                              ? Border.all(
                                  width: 4,
                                  color: kPrimaryAccentColor,
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: videoControllerNotifier.isInitialized
                            ? Row(
                                children: [
                                  Text(
                                    _formatDuration(
                                        videoControllerNotifier.position),
                                    style: TextStyle(
                                      color: hasFocus
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: hasFocus
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor:
                                            Colors.white.withOpacity(0.3),
                                        thumbColor: Colors.white,
                                        overlayColor:
                                            Colors.white.withOpacity(0.2),
                                        trackHeight: 3.0,
                                      ),
                                      child: Slider(
                                        value: videoControllerNotifier
                                                    .duration.inMilliseconds >
                                                0
                                            ? videoControllerNotifier
                                                    .position.inMilliseconds /
                                                videoControllerNotifier
                                                    .duration.inMilliseconds
                                            : 0.0,
                                        onChanged: (value) {
                                          final position = Duration(
                                            milliseconds: (value *
                                                    videoControllerNotifier
                                                        .duration
                                                        .inMilliseconds)
                                                .round(),
                                          );
                                          seekTo(position);
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(
                                        videoControllerNotifier.duration),
                                    style: TextStyle(
                                      color: hasFocus
                                          ? Colors.white
                                          : Colors.grey[700],
                                      fontSize: 14,
                                      fontWeight: hasFocus
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    }),
                  ),

                  const SizedBox(height: 5),

                  // Play/Pause button
                  Focus(
                    focusNode: playPauseFocus,
                    child: Builder(builder: (context) {
                      final hasFocus =
                          isFocused.value && currentFocusedIndex.value == 2;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: hasFocus
                              ? Border.all(
                                  width: 4,
                                  color: kPrimaryAccentColor,
                                )
                              : null,
                        ),
                        child: videoControllerNotifier.isInitialized
                            ? IconButton(
                                onPressed: togglePlayPause,
                                icon: Icon(
                                  videoControllerNotifier.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: hasFocus
                                      ? Colors.white
                                      : Colors.grey[700],
                                  size: 32,
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    }),
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
