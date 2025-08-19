import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/shared_widgets/button.dart';

import '../../../core/shared_widgets/mini_player_widget.dart';

class FullScreenMiniPlayerScreen extends HookWidget {
  final String videoUrl;

  const FullScreenMiniPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = useState(false);
    final currentPosition = useState(Duration.zero);
    final totalDuration = useState(Duration.zero);
    final isLoading = useState(false);
    final showControls = useState(true);
    final controlsTimer = useRef<Timer?>(null);

    // Animation controller for entrance effect
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    // Entrance animation
    final entranceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start entrance animation
    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    // Method channel for communicating with the mini player
    const methodChannel = MethodChannel('mini_player_view_channel');

    // Request player state from native side
    void requestPlayerState(MethodChannel channel) async {
      try {
        final result = await channel.invokeMethod('getPlayerState');
        if (result is Map) {
          isPlaying.value = result['isPlaying'] ?? false;
          totalDuration.value = Duration(milliseconds: result['duration'] ?? 0);
        }
      } catch (e) {
        debugPrint('Error getting player state: $e');
      }
    }

    // Request current position from native side
    void requestCurrentPosition(MethodChannel channel) async {
      try {
        final result = await channel.invokeMethod('getCurrentPosition');
        if (result is int) {
          currentPosition.value = Duration(milliseconds: result);
        }
      } catch (e) {
        debugPrint('Error getting current position: $e');
      }
    }

    // Initialize and start listening for updates
    useEffect(() {
      // Request current player state
      requestPlayerState(methodChannel);

      // Set up periodic updates for position
      final timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        requestCurrentPosition(methodChannel);
      });

      return () {
        timer.cancel();
        controlsTimer.value?.cancel();
      };
    }, []);

    // Hide controls after 3 seconds of inactivity
    useEffect(() {
      if (showControls.value) {
        controlsTimer.value?.cancel();
        controlsTimer.value = Timer(const Duration(seconds: 3), () {
          showControls.value = false;
        });
      }
      return null;
    }, [showControls.value]);

    // Toggle play/pause
    void togglePlayPause() async {
      try {
        isLoading.value = true;
        final result = await methodChannel.invokeMethod(
          isPlaying.value ? 'pause' : 'play',
        );
        if (result == true) {
          isPlaying.value = !isPlaying.value;
        }
      } catch (e) {
        debugPrint('Error toggling play/pause: $e');
      } finally {
        isLoading.value = false;
      }
    }

    // Seek to position
    void seekTo(Duration position) async {
      try {
        await methodChannel.invokeMethod('seekTo', {
          'position': position.inMilliseconds,
        });
        currentPosition.value = position;
      } catch (e) {
        debugPrint('Error seeking: $e');
      }
    }

    // Format duration for display
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      if (hours > 0) {
        return '$twoDigits(hours):$twoDigits(minutes):$twoDigits(seconds)';
      }
      return '$twoDigits(minutes):$twoDigits(seconds)';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            // Show controls on any arrow key press
            if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              showControls.value = true;
              // Reset the timer to hide controls after 3 seconds
              controlsTimer.value?.cancel();
              controlsTimer.value = Timer(const Duration(seconds: 3), () {
                showControls.value = false;
              });
            }
          }
        },
        child: GestureDetector(
          onTap: () {
            showControls.value = !showControls.value;
          },
          child: Stack(
            children: [
              SizedBox.expand(
                child: ScaleTransition(
                  scale: entranceAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'mini-player-hero',
                      child: MiniPlayerWidget(
                        videoUrl: videoUrl,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),

              // Controls overlay
              if (showControls.value)
                Positioned.fill(
                  child: FadeTransition(
                    opacity: entranceAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top controls (back button)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  AppButton(
                                    text: 'Back',
                                    onTap: () => Navigator.of(context).pop(),
                                    prefix: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom controls row (play/pause button and seek bar)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Play/Pause button
                                  GestureDetector(
                                    onTap: togglePlayPause,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPlaying.value
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Seek bar and time display
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Seek bar
                                        SliderTheme(
                                          data:
                                              SliderTheme.of(context).copyWith(
                                            activeTrackColor: kPrimaryColor,
                                            inactiveTrackColor:
                                                Colors.grey.withOpacity(0.3),
                                            thumbColor: kPrimaryColor,
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                              enabledThumbRadius: 8,
                                            ),
                                          ),
                                          child: Slider(
                                            value: totalDuration
                                                        .value.inMilliseconds >
                                                    0
                                                ? currentPosition
                                                        .value.inMilliseconds /
                                                    totalDuration
                                                        .value.inMilliseconds
                                                : 0.0,
                                            onChanged: (value) {
                                              final newPosition = Duration(
                                                milliseconds: (value *
                                                        totalDuration.value
                                                            .inMilliseconds)
                                                    .round(),
                                              );
                                              seekTo(newPosition);
                                            },
                                          ),
                                        ),

                                        // Time display
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formatDuration(
                                                  currentPosition.value),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              formatDuration(
                                                  totalDuration.value),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
