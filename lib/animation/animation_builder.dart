import 'package:flutter/material.dart';

import 'loading_animator.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

class AnimationBuilder<T> extends StatelessWidget {
  const AnimationBuilder({
    Key key,
    @required this.animator,
    @required this.builder,
    this.minHeight,
  }) : super(key: key);

  final LoadingAnimator animator;
  final WidgetBuilder builder;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    Widget current = builder(context);

    if (minHeight != null) {
      current = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: current,
      );
    }

    if (animator != null) {
      current = FadeTransition(
        opacity: animator.opacity,
        child: current,
      );
    }

    return current;
  }
}
