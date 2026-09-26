// Back icon geometry adapted from Light SDK ic_back_white.xml.
// https://github.com/lightphone/light-sdk/blob/main/sdk/ui/src/main/res/drawable/ic_back_white.xml
//
// MIT License
// Copyright (c) 2026 The Light Phone
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';

// LightTopBar uses three grid units and Fine typography on the LP3 canvas.
const lightToolbarHeight = 40.0;
const lightHeaderTitleStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 17,
  height: 1.15,
  letterSpacing: 0.51,
  fontWeight: FontWeight.w400,
);

/// The SDK's shaft-free back chevron, independent of platform icon fonts.
/// Its surrounding button provides the Back label and tap target.
class LightBackChevron extends StatelessWidget {
  const LightBackChevron({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 80 / 3,
        child: CustomPaint(
          painter: _LightBackPainter(color ??
              IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurface),
        ),
      );
}

class _LightBackPainter extends CustomPainter {
  const _LightBackPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 30);
    canvas.drawPath(
      Path()
        ..moveTo(14, 4)
        ..lineTo(5.718, 12.282)
        ..lineTo(3, 15)
        ..lineTo(5.718, 17.718)
        ..lineTo(14, 26)
        ..lineTo(16.118, 23.6)
        ..lineTo(7.435, 15)
        ..lineTo(16.118, 6.3)
        ..close(),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LightBackPainter oldDelegate) =>
      color != oldDelegate.color;
}
