import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

/// Wraps a skeleton layout in the shimmer sweep.
///
/// Skeletons are built to the same geometry as the widget they stand in for —
/// same sizes, same spacing, same corner radii — so content does not jump when
/// it arrives.
class Skeleton extends StatelessWidget {
  final Widget child;

  const Skeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surfaceLight,
      child: child,
    );
  }
}

/// A block standing in for an image or a tag, sized like the real one.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A line of text. [fontSize] is the size of the text it replaces; the bar is
/// drawn a little shorter, the way a line of type reads on the page.
class SkeletonLine extends StatelessWidget {
  final double width;
  final double fontSize;

  const SkeletonLine({super.key, required this.width, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: fontSize * 0.72, radius: 4);
  }
}

/// A circle, for avatars and round icon buttons.
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
