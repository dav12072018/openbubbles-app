import 'package:flutter/material.dart';

/// A purely presentational inbox row, shared by the live inbox and UI previews.
/// It deliberately does not depend on contacts, the database, or native services.
class LightConversationRow extends StatelessWidget {
  const LightConversationRow({
    super.key,
    required this.title,
    required this.preview,
    required this.timestamp,
    this.deliveryStatus,
    this.unread = false,
    this.pinned = false,
    this.muted = false,
    this.selected = false,
    this.highlighted = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
  });

  final Widget title;
  final Widget preview;
  final String timestamp;
  final String? deliveryStatus;
  final bool unread;
  final bool pinned;
  final bool muted;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canvas = Theme.of(context).scaffoldBackgroundColor;
    final inverse = selected || highlighted;
    final foreground = inverse ? canvas : colors.onBackground;
    final background = inverse ? colors.onBackground : canvas;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTapUp: onSecondaryTapUp,
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: colors.onBackground, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (selected) ...[
                      Icon(Icons.check, size: 18, color: foreground),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                            color: foreground,
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            height: 1.25),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: title,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'Unread',
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: foreground, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Text(
                      timestamp,
                      style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                            color: foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: preview,
                      ),
                    ),
                    if (deliveryStatus?.isNotEmpty ?? false) ...[
                      const SizedBox(width: 10),
                      Text(deliveryStatus!,
                          style: TextStyle(color: foreground, fontSize: 12)),
                    ],
                    if (pinned) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.push_pin_outlined,
                          size: 14, color: foreground, semanticLabel: 'Pinned'),
                    ],
                    if (muted) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.notifications_off_outlined,
                          size: 14, color: foreground, semanticLabel: 'Muted'),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
