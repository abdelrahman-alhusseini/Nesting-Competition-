import 'package:flutter/material.dart';

class ImageHotspot extends StatelessWidget {
  const ImageHotspot({
    required this.rect,
    required this.onTap,
    required this.label,
    super.key,
  });

  final Rect rect;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: Colors.white.withValues(alpha: 0.025),
            splashColor: const Color(0xFFFFBC12).withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
