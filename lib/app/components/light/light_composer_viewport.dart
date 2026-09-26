import 'package:flutter/material.dart';

/// Keeps the composer reachable above the keyboard on the short LP3 display.
/// Replies, attachment previews and a multiline draft can scroll inside this
/// viewport instead of pushing the transcript and send action off screen.
/// The parent bounds this non-flex child using LayoutBuilder's actual body
/// constraints, which reflect keyboard insets already consumed by Scaffold.
/// Short composers retain their natural height so the transcript gets the rest.
class LightComposerViewport extends StatelessWidget {
  const LightComposerViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final available = (media.size.height -
            media.viewInsets.bottom -
            media.padding.vertical -
            kToolbarHeight)
        .clamp(1.0, double.infinity);
    final height = (available * 0.65).clamp(48.0, 300.0).clamp(1.0, available);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: SingleChildScrollView(reverse: true, child: child),
    );
  }
}
