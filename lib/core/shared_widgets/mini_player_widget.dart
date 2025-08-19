import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/loading_overlay.dart';
import 'package:latest_movies/features/movies/controllers/native_player_controller.dart';

class MiniPlayerWidget extends HookConsumerWidget {
  final String videoUrl;
  final VoidCallback? onTap;
  final String? heroTag;

  const MiniPlayerWidget({
    super.key,
    required this.videoUrl,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocussed = useState(false);

    return Focus(
      autofocus: false,
      onFocusChange: (focused) {
        log("MiniPlayer focus: $focused");
        isFocussed.value = focused;
      },
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          // Call onTap callback if provided, otherwise use default behavior
          if (onTap != null) {
            onTap!();
          } else {
            ref
                .read(nativePlayerCtrlProvider(NativePlayerControllerArgs(
                  loadingOverlay: LoadingOverlay.of(context),
                  videoUrl: videoUrl,
                )))
                .navigateToPlayer();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocussed.value ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: heroTag != null
            ? Hero(
                tag: heroTag!,
                child: PlatformViewLink(
                  viewType: 'mini-player-view',
                  surfaceFactory: (context, controller) {
                    return AndroidViewSurface(
                      controller: controller as AndroidViewController,
                      gestureRecognizers: const <Factory<
                          OneSequenceGestureRecognizer>>{},
                      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    );
                  },
                  onCreatePlatformView: (params) {
                    final controller =
                        PlatformViewsService.initSurfaceAndroidView(
                      id: params.id,
                      viewType: 'mini-player-view',
                      layoutDirection: TextDirection.ltr,
                      creationParams: {'videoUrl': videoUrl},
                      creationParamsCodec: const StandardMessageCodec(),
                      onFocus: () {
                        log("MiniPlayer: onFocus called from Flutter");
                      },
                    )
                          ..addOnPlatformViewCreatedListener(
                              params.onPlatformViewCreated)
                          ..create();

                    return controller;
                  },
                ),
              )
            : PlatformViewLink(
                viewType: 'mini-player-view',
                surfaceFactory: (context, controller) {
                  return AndroidViewSurface(
                    controller: controller as AndroidViewController,
                    gestureRecognizers: const <Factory<
                        OneSequenceGestureRecognizer>>{},
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                  );
                },
                onCreatePlatformView: (params) {
                  final controller =
                      PlatformViewsService.initSurfaceAndroidView(
                    id: params.id,
                    viewType: 'mini-player-view',
                    layoutDirection: TextDirection.ltr,
                    creationParams: {'videoUrl': videoUrl},
                    creationParamsCodec: const StandardMessageCodec(),
                    onFocus: () {
                      log("MiniPlayer: onFocus called from Flutter");
                    },
                  )
                        ..addOnPlatformViewCreatedListener(
                            params.onPlatformViewCreated)
                        ..create();

                  return controller;
                },
              ),
      ),
    );
  }
}
