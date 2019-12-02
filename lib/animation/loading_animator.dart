import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

import 'animator.dart';

/// Loading animator
///
/// Create animation and its controller.
///
/// Example:
///
/// class AbcPage extends StatefulWidget { ... }
/// class _AbcPageState extends State<AbcPage> with SingleTickerProviderStateMixin {
///   ...
///   @override
///   void initState() {
///     super.initState();
///     animator.init(this);
///   }
/// }
class LoadingAnimator extends Animator {
  LoadingAnimator({
    this.duration = const Duration(seconds: 1),
    this.onFinished,
  });

  AnimationController _controller;
  Animation<double> opacity;
  Duration duration;
  bool isProcessing = false;
  VoidCallback onFinished;

  bool get initialized => _controller != null && opacity != null;

  /// Provide ticker for animation.
  ///
  /// Animation requires ticker for scheduling it. We use basic implementation for [StatefulWidget]
  /// ticker provider: [SingleTickerProviderStateMixin], [TickerProviderStateMixin]
  /// If you have a animation is used please use a [SingleTickerProviderStateMixin]. If not use
  /// [TickerProviderStateMixin]
  ///
  void init(TickerProvider tickerProvider, {double initialValue = 100.0}) {
    _controller = AnimationController(
      value: initialValue,
      duration: duration,
      vsync: tickerProvider,
    );
    opacity = Tween<double>(begin: 0.0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isProcessing = false;
        if (onFinished != null) {
          onFinished();
        }
      }
    });
  }

  TickerFuture startAnimation() {
    assert(initialized,
        'Animator is not initialized. Please call "init()" function before using it');
    if (isProcessing) {
      // Animation is already started.
      return null;
    }
    isProcessing = true;
    return _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
  }
}
