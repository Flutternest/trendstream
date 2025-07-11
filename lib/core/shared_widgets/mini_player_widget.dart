import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MiniPlayerWidget extends StatelessWidget {
  final String videoUrl;

  const MiniPlayerWidget({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'mini-player-view',
      creationParams: {'videoUrl': videoUrl},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
