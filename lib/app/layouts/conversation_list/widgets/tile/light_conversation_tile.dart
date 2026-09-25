import 'dart:async';

import 'package:bluebubbles/app/components/light/light_conversation_row.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/tile/conversation_tile.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LightConversationTile extends CustomStateful<ConversationTileController> {
  const LightConversationTile({
    super.key,
    required super.parentController,
    required this.deletedMode,
  });

  final bool deletedMode;

  @override
  State<LightConversationTile> createState() => _LightConversationTileState();
}

class _LightConversationTileState extends CustomState<LightConversationTile,
    void, ConversationTileController> {
  Message? latestMessage;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    tag = controller.chat.guid;
    forceDelete = false;
    latestMessage = controller.chat.latestMessage;

    if (widget.deletedMode) return;
    if (kIsWeb) {
      subscription = WebListeners.newMessage.listen((event) {
        if (event.item2?.guid == controller.chat.guid) {
          setState(() => latestMessage = event.item1);
        }
      });
    } else {
      updateObx(() {
        final query = (Database.messages.query(Message_.dateDeleted.isNull())
              ..link(Message_.chat, Chat_.guid.equals(controller.chat.guid))
              ..order(Message_.dateCreated, flags: Order.descending))
            .watch();
        subscription = query.listen((query) async {
          final message = await runAsync(() => query.findFirst());
          setState(() => latestMessage = message);
        });
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = Theme.of(context).colorScheme;
      final selected = controller.isSelected;
      final highlighted = controller.shouldHighlight.value;
      final foreground = selected || highlighted
          ? Theme.of(context).scaffoldBackgroundColor
          : colors.onBackground;
      final unread = GlobalChatService.unreadState(controller.chat.guid).value;
      final muted =
          GlobalChatService.muteState(controller.chat.guid).value == 'mute';
      final typing = !widget.deletedMode &&
          cvc(controller.chat).showTypingIndicatorFor.isNotEmpty;
      String? deliveryStatus;
      if ((latestMessage?.error ?? 0) > 0) {
        deliveryStatus = 'Not sent';
      } else if (ss.settings.statusIndicatorsOnChats.value &&
          (latestMessage?.isFromMe ?? false) &&
          !controller.chat.isGroup) {
        final indicator = latestMessage?.indicatorToShow ?? Indicator.NONE;
        if (indicator != Indicator.NONE) {
          deliveryStatus = indicator.name.toLowerCase().capitalizeFirst;
        }
      }

      final deletedCount = widget.deletedMode
          ? controller.chat.messages
              .where((message) => message.dateDeleted != null)
              .length
          : 0;
      final preview = widget.deletedMode
          ? Text('$deletedCount deleted message${deletedCount == 1 ? '' : 's'}')
          : typing
              ? const Text('Typing…')
              : controller.subtitle ??
                  ChatSubtitle(
                    parentController: controller,
                    maxLines: 1,
                    style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.3),
                  );

      return LightConversationRow(
        title: ChatTitle(
          parentController: controller,
          maxLines: 1,
          style: TextStyle(
              color: foreground,
              fontSize: 21,
              fontWeight: FontWeight.w400,
              height: 1.25),
        ),
        preview: preview,
        timestamp: widget.deletedMode
            ? ''
            : buildChatListDateMaterial(latestMessage?.chatViewDate),
        deliveryStatus: widget.deletedMode ? null : deliveryStatus,
        unread: !widget.deletedMode && unread,
        pinned: controller.chat.isPinned ?? false,
        muted: muted,
        selected: selected,
        highlighted: highlighted,
        onTap: () => controller.onTap(context, widget.deletedMode),
        onLongPress: widget.deletedMode ? null : controller.onLongPress,
        onSecondaryTapUp: widget.deletedMode
            ? null
            : (details) => controller.onSecondaryTap(context, details),
      );
    });
  }
}
