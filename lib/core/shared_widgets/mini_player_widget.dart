import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/providers/video_player_controller_provider.dart';
import 'package:latest_movies/core/router/router.dart';
import 'package:latest_movies/core/shared_widgets/video_player_widget.dart';

class MiniPlayerWidget extends HookConsumerWidget {
  final String videoUrl;

  const MiniPlayerWidget({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocussed = useState(false);
    final heroTag = 'video_player_${videoUrl.hashCode}';

    return Focus(
      autofocus: false,
      onFocusChange: (focused) {
        log("MiniPlayer focus: $focused");
        isFocussed.value = focused;
      },
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          log("MiniPlayer key event: $event");
          
          // Unmute video and navigate to full-screen player with Hero animation
          if (isFocussed.value) {
            ref.read(videoPlayerControllerProvider(videoUrl).notifier).unmute();
            AppRouter.navigateToPage(
              Routes.fullScreenPlayerView,
              arguments: {
                'videoUrl': videoUrl,
                'heroTag': heroTag,
              },
            );
          }
          isFocussed.value = false;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isFocussed.value ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: VideoPlayerWidget(
            videoUrl: videoUrl,
            heroTag: heroTag,
            showControls: false,
            autoPlay: false,
            aspectRatio: 16 / 9,
            isUsedInMiniPlayer: true,
          ),
        ),
      ),
    );
  }
}
