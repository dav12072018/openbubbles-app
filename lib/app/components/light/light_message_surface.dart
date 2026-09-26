import 'package:flutter/material.dart';
import 'light_theme.dart';

/// Plain message text shared by the live transcript and preview.
/// Text follows message direction; only selection adds a background.
class LightMessageSurface extends StatelessWidget {
  const LightMessageSurface({
    super.key,
    required this.isFromMe,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
    this.constraints,
  });

  final bool isFromMe;
  final bool selected;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = selected ? colors.tertiaryContainer : Colors.transparent;
    final foreground = selected ? colors.onTertiaryContainer : colors.onSurface;
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
      ),
      child: DefaultTextStyle(
        style: lightMessageTextStyle.copyWith(color: foreground),
        textAlign: isFromMe ? TextAlign.right : TextAlign.left,
        child: child,
      ),
    );
  }
}
