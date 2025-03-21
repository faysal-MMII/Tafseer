import 'package:flutter/material.dart';

/// A widget that creates a shimmer animation effect for loading states.
/// 
/// This widget applies a gradient animation to create a shimmering effect
/// over placeholder UI elements, providing a more engaging loading experience.
class ShimmerLoadingEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerLoadingEffect({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  _ShimmerLoadingEffectState createState() => _ShimmerLoadingEffectState();
}

class _ShimmerLoadingEffectState extends State<ShimmerLoadingEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

// Predefined shimmer widgets
class ShimmerPlaceholders {
  // Text line placeholder
  static Widget textLine({
    double width = double.infinity,
    double height = 16.0,
    BorderRadius? borderRadius,
  }) {
    return ShimmerLoadingEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  // Card placeholder
  static Widget card({
    double width = double.infinity,
    double height = 100.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
  }) {
    return ShimmerLoadingEffect(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Answer placeholder for QuranSection or HadithSection
  static Widget answerPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textLine(width: 150, height: 24),
          const SizedBox(height: 16),
          textLine(),
          const SizedBox(height: 8),
          textLine(),
          const SizedBox(height: 8),
          textLine(width: 200),
          const SizedBox(height: 16),
          textLine(width: 180, height: 20),
          const SizedBox(height: 16),
          card(height: 60),
          const SizedBox(height: 8),
          card(height: 60),
        ],
      ),
    );
  }
}