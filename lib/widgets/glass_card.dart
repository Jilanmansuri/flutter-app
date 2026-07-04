import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color borderGradientColor;
  final Color bgGradientColor;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 15.0,
    this.borderGradientColor = const Color(0x33FFFFFF),
    this.bgGradientColor = const Color(0x0AFFFFFF),
    this.padding = const EdgeInsets.all(20.0),
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderGradientColor,
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ?? [
                bgGradientColor.withValues(alpha: 0.08),
                bgGradientColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
