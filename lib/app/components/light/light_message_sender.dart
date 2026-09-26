import 'package:flutter/material.dart';

/// A quiet sender caption above a plain-text message or voice note.
class LightMessageSender extends StatelessWidget {
  const LightMessageSender({
    super.key,
    required this.name,
    this.isFromMe = false,
  });

  final String name;
  final bool isFromMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        name,
        textAlign: isFromMe ? TextAlign.right : TextAlign.left,
        style: theme.textTheme.labelMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
