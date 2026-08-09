import 'dart:ui';

import 'package:flutter/material.dart';

/// Displays each 1672 x 941 artwork page without stretching or cropping it.
///
/// The centered canvas always keeps the original aspect ratio. Any remaining
/// browser space is filled with a soft extension of the same artwork rather
/// than a hard black bar. New light-theme screens opt into [lightBackground].
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    required this.assetPath,
    required this.children,
    this.lightBackground = false,
    super.key,
  });

  static const double width = 1672;
  static const double height = 941;

  final String assetPath;
  final List<Widget> children;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;
        final double scale = (viewportWidth / width < viewportHeight / height)
            ? viewportWidth / width
            : viewportHeight / height;
        final double canvasWidth = width * scale;
        final double canvasHeight = height * scale;

        final Color baseColor = lightBackground
            ? const Color(0xFFF2F7FC)
            : const Color(0xFF010814);

        return ColoredBox(
          color: baseColor,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Transform.scale(
                      scale: 1.12,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        color: lightBackground
                            ? const Color(0xE8FFFFFF)
                            : const Color(0xCCFFFFFF),
                        colorBlendMode: BlendMode.modulate,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: lightBackground
                        ? const LinearGradient(
                            colors: <Color>[
                              Color(0xB8F7FAFD),
                              Color(0x55FFFFFF),
                              Color(0xB8F7FAFD),
                            ],
                          )
                        : const LinearGradient(
                            colors: <Color>[
                              Color(0x66000818),
                              Color(0x22000818),
                              Color(0x66000818),
                            ],
                          ),
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Image.asset(
                            assetPath,
                            width: width,
                            height: height,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
