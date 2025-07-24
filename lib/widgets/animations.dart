import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Memory-Safe Slide Transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Offset begin;
  final Offset end;

  SlidePageRoute({
    required this.child,
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration(milliseconds: 400), // Reduced for performance
          reverseTransitionDuration: Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Simplified for better performance
            var slideAnimation = Tween(begin: begin, end: end).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Interval(0.0, 0.7, curve: Curves.easeOut),
              ),
            );

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

// Optimized Scale Transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ScalePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration(milliseconds: 500),
          reverseTransitionDuration: Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            );

            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}

// Simplified Hero Route (Less Complex)
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Color backgroundColor;

  HeroPageRoute({
    required this.child,
    this.backgroundColor = Colors.white,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration(milliseconds: 600),
          reverseTransitionDuration: Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            var scaleAnimation = Tween(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  color: backgroundColor,
                  child: child,
                ),
              ),
            );
          },
        );
}

// Memory-Safe Staggered Animation
class StaggeredAnimationWrapper extends StatefulWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const StaggeredAnimationWrapper({
    Key? key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
  }) : super(key: key);

  @override
  _StaggeredAnimationWrapperState createState() => _StaggeredAnimationWrapperState();
}

class _StaggeredAnimationWrapperState extends State<StaggeredAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ Critical: Always dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Optimized Floating Animation (Stops when not visible)
class FloatingAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FloatingAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  _FloatingAnimationState createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => false; // Don't keep alive when not visible

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _animation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Only start if widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.stop(); // ✅ Stop before disposing
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

// Smart Pulse Animation (Pauses when app is backgrounded)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ Monitor app lifecycle
    
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _animation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (mounted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Pause animations when app is backgrounded
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.stop();
        break;
      case AppLifecycleState.resumed:
        if (mounted) {
          _controller.repeat(reverse: true);
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

// Ultra-Safe Ka'aba FAB
class ModernKaabaFAB extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final double size;

  const ModernKaabaFAB({
    Key? key,
    required this.isExpanded,
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    this.size = 60.0,
  }) : super(key: key);

  @override
  _ModernKaabaFABState createState() => _ModernKaabaFABState();
}

class _ModernKaabaFABState extends State<ModernKaabaFAB>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _tapController;
  late AnimationController _expandController;
  late AnimationController _pulseController;
  
  late Animation<double> _tapScaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _expandScaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize controllers
    _tapController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    
    _expandController = AnimationController(
      duration: Duration(milliseconds: 400), // Reduced for performance
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutBack),
    );

    _expandScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start pulse only if mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause animations when app is backgrounded
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pulseController.stop();
        break;
      case AppLifecycleState.resumed:
        if (mounted && !widget.isExpanded) {
          _pulseController.repeat(reverse: true);
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        _pulseController.stop();
        break;
    }
  }

  @override
  void didUpdateWidget(ModernKaabaFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _pulseController.stop(); // Stop pulse when expanded
        _expandController.forward();
      } else {
        _expandController.reverse();
        if (mounted) {
          _pulseController.repeat(reverse: true); // Resume pulse
        }
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (mounted) {
      setState(() => _isPressed = true);
      _tapController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (mounted) {
      setState(() => _isPressed = false);
      _tapController.reverse();
    }
  }

  void _handleTapCancel() {
    if (mounted) {
      setState(() => _isPressed = false);
      _tapController.reverse();
    }
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // ✅ Proper disposal order
    _pulseController.stop();
    _tapController.stop();
    _expandController.stop();
    
    _tapController.dispose();
    _expandController.dispose();
    _pulseController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _tapController,
          _expandController,
          if (!widget.isExpanded) _pulseController, // Only pulse when not expanded
        ]),
        builder: (context, child) {
          final tapScale = _tapScaleAnimation.value;
          final expandScale = _expandScaleAnimation.value;
          final pulseScale = widget.isExpanded ? 1.0 : _pulseAnimation.value;
          final combinedScale = tapScale * expandScale * pulseScale;

          return Transform.scale(
            scale: combinedScale,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.3),
                      blurRadius: 10, // Reduced for performance
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}