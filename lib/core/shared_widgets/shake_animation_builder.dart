import 'package:flutter/material.dart';

class ShakeErrorController {
  late void Function() trigger;
}

class ShakeErrorAnimation extends StatefulWidget {
  final Widget child;
  final ShakeErrorController controller;
  final Duration duration;
  final double offset;

  const ShakeErrorAnimation({
    Key? key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10.0,
  }) : super(key: key);

  @override
  State<ShakeErrorAnimation> createState() => _ShakeErrorAnimationState();
}

class _ShakeErrorAnimationState extends State<ShakeErrorAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -widget.offset), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -widget.offset, end: widget.offset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: widget.offset, end: -widget.offset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -widget.offset, end: widget.offset), weight: 2),
      TweenSequenceItem(tween: Tween(begin: widget.offset, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _animationController, curve: Curves.linear));

    widget.controller.trigger = () {
      _animationController.forward(from: 0.0);
    };
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}
