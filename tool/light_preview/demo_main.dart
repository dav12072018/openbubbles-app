import 'package:flutter/material.dart';

import 'demo_app.dart';

void main() => runApp(const _DemoFrame());

class _DemoFrame extends StatelessWidget {
  const _DemoFrame();

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 600) return const LightDemoApp();
          return ColoredBox(
            color: const Color(0xFFE8E8E8),
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  width: 360,
                  height: (constraints.maxHeight - 100).clamp(200.0, 413.0),
                  child: const ClipRect(child: LightDemoApp())),
              const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Text(
                    'Interactive local demo · Light Phone III layout\nSample data only. No real messages are sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF444444)),
                  )),
            ])),
          );
        }),
      );
}
