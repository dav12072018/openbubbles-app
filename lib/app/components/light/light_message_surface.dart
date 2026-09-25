import 'package:flutter/material.dart';

/// Square, monochrome message treatment shared by the live transcript and preview.
/// Direction remains legible through alignment and fill, without relying on color.
class LightMessageSurface extends StatelessWidget {
  const LightMessageSurface({
    super.key,
    required this.isFromMe,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
    final background = selected
        ? colors.tertiaryContainer
        : isFromMe
            ? colors.primary
            : theme.scaffoldBackgroundColor;
    final foreground = selected
        ? colors.onTertiaryContainer
        : isFromMe
            ? colors.onPrimary
            : colors.onSurface;
    return Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
            color: isFromMe ? background : colors.outlineVariant, width: 0.5),
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyLarge!.copyWith(color: foreground),
        child: child,
      ),
    );
  }
}
