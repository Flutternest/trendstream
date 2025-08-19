import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/loading_overlay.dart';

class NativePlayerControllerArgs {
  final LoadingOverlay? loadingOverlay;
  final String videoUrl;

  const NativePlayerControllerArgs({
    required this.loadingOverlay,
    required this.videoUrl,
  });


  @override
  String toString() {
    return 'NativePlayerControllerArgs(loadingOverlay: $loadingOverlay, videoUrl: $videoUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativePlayerControllerArgs &&
        ((other.loadingOverlay == loadingOverlay) || (other.loadingOverlay == null && loadingOverlay == null)) &&
        other.videoUrl == videoUrl;
  }

  @override
  int get hashCode => (loadingOverlay?.hashCode ?? 0) ^ videoUrl.hashCode;
}

final nativePlayerCtrlProvider =
    ChangeNotifierProvider.family<NativePlayerController, NativePlayerControllerArgs>(
        (ref, arg) {
  return NativePlayerController(arg);
});

class NativePlayerController extends ChangeNotifier {
  final methodChannel =
      const MethodChannel('com.example.latest_movies/channel');

  final NativePlayerControllerArgs _arg;

  NativePlayerController(this._arg);

  bool isLoading = false;

  Future<void> navigateToPlayer({bool setLoading = false}) async {
    try {
      if (setLoading) {
        isLoading = true;
        notifyListeners();
      } else {
        if (_arg.loadingOverlay != null) {
          _arg.loadingOverlay!.show(text: 'Loading...');
        }
      }
      
      await Future.delayed(const Duration(seconds: 3));
      await methodChannel.invokeMethod("navigateToPlayer", {
        "videoUrl": _arg.videoUrl,
      });
      if (setLoading) {
        isLoading = false;
        notifyListeners();
      } else {
        if (_arg.loadingOverlay != null) {
          _arg.loadingOverlay!.hide();
        }
      }
    } catch (e) {
      if (setLoading) {
        isLoading = false;
        notifyListeners();
      } else {
        if (_arg.loadingOverlay != null) {
          _arg.loadingOverlay!.hide();
        }
      }
      rethrow;
    }
  }
}
