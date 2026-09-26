import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/app/components/light/light_message_sender.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageSender extends StatelessWidget {
  const MessageSender(
      {super.key, required this.message, required this.olderMessage});

  final Message message;
  final Message? olderMessage;

  @override
  Widget build(BuildContext context) {
    if (ss.settings.skin.value == Skins.Light) {
      final name = message.handle?.displayName.trim();
      return LightMessageSender(
        name: message.isFromMe == true
            ? 'You'
            : name == null || name.isEmpty
                ? 'Unknown sender'
                : name,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25)
          .add(const EdgeInsets.only(bottom: 3)),
      child: Text(
        message.handle?.displayName ?? "",
        style: context.theme.textTheme.labelMedium!.copyWith(
            color: context.theme.colorScheme.outline,
            fontWeight: FontWeight.normal),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
