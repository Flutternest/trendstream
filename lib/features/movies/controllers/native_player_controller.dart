import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/loading_overlay.dart';

class NativePlayerControllerArgs {
  final LoadingOverlay loadingOverlay;
  final String videoUrl;

  const NativePlayerControllerArgs({
    required this.loadingOverlay,
    required this.videoUrl,
  });
}

final nativePlayerCtrlProvider =
    Provider.family<NativePlayerController, NativePlayerControllerArgs>(
        (ref, arg) {
  return NativePlayerController(arg);
});

class NativePlayerController {
  final methodChannel =
      const MethodChannel('com.example.latest_movies/channel');

  final NativePlayerControllerArgs _arg;

  NativePlayerController(this._arg);

  Future<void> navigateToPlayer() async {
    try {
      _arg.loadingOverlay.show(text: 'Loading...');
      await methodChannel.invokeMethod("navigateToPlayer", {
        "videoUrl": _arg.videoUrl,
      });
      _arg.loadingOverlay.hide();
    } catch (e) {
      _arg.loadingOverlay.hide();
      rethrow;
    }
  }
}
