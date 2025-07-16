import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MiniPlayerWidget extends HookWidget {
  final String videoUrl;

  const MiniPlayerWidget({super.key, required this.videoUrl});

  static const methodChannel = 'mini_player_view_channel';

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      const MethodChannel(methodChannel).setMethodCallHandler((call) async {
        if (call.method == "onRootTapped") {
          log("Native root tapped!");
          const platform = MethodChannel('com.example.latest_movies/channel');
          await platform.invokeMethod("navigateToPlayer");
        }
      });
      return null;
    }, []);

    return Focus(
      autofocus: true,
      onFocusChange: (focused) {
        log("MiniPlayer focus: $focused");
        const MethodChannel(methodChannel).invokeMethod("requestNativeFocus");
      },
      child: PlatformViewLink(
        viewType: 'mini-player-view',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
            },
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          final controller = PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'mini-player-view',
            layoutDirection: TextDirection.ltr,
            creationParams: {'videoUrl': videoUrl},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              log("MiniPlayer: onFocus called from Flutter");
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();

          return controller;
        },
      ),
    );
  }
}
