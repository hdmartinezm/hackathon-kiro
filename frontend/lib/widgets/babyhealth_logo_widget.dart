import 'package:flutter/material.dart';

/// Official BabyHealth logo widget.
///
/// Draws a primary-blue circle with a baby face icon inside.
/// The [size] parameter controls the overall diameter (default 60).
class BabyHealthLogoWidget extends StatelessWidget {
  final double size;

  const BabyHealthLogoWidget({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF389BB0),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.child_care_rounded,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}
