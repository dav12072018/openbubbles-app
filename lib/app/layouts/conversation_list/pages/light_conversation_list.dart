import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/header/header_widgets.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/tile/list_item.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// The Light skin keeps the existing inbox data and actions in a quiet,
/// text-first layout. The bottom controls remain reachable on a small display.
class LightConversationList extends CustomStateful<ConversationListController> {
  const LightConversationList({super.key, required super.parentController});

  @override
  State<LightConversationList> createState() => _LightConversationListState();
}

class _LightConversationListState extends CustomState<LightConversationList,
    void, ConversationListController> {
  bool get isSubpage =>
      controller.showArchivedChats ||
      controller.showUnknownSenders ||
      controller.showDeletedMessages;

  String get title => controller.showArchivedChats
      ? 'Archive'
      : controller.showUnknownSenders
          ? 'Unknown senders'
          : controller.showDeletedMessages
              ? 'Recently deleted'
              : 'Messages';

  @override
  void initState() {
    super.initState();
    // The surrounding ConversationList owns the controller's lifetime.
    forceDelete = false;
  }

  void close() {
    if (controller.selectedChats.isNotEmpty) {
      controller.clearSelectedChats();
    } else if (isSubpage) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  void applyToSelection(void Function(Chat) action) {
    // Mutations can remove a chat from this inbox; take a stable copy first.
    final selected = List<Chat>.from(controller.selectedChats);
    controller.clearSelectedChats();
    for (final chat in selected) {
      action(chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = controller.selectedChats;
    final selecting = selected.isNotEmpty;
    final foreground = colors.onBackground;
    final border = BorderSide(color: foreground, width: 0.5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              if (selecting || isSubpage)
                Container(
                  height: 48,
                  decoration: BoxDecoration(border: Border(bottom: border)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: Text(
                          selecting ? '${selected.length} selected' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selecting || isSubpage)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: selecting ? 'Cancel selection' : 'Back',
                            onPressed: close,
                            icon: Icon(
                                selecting ? Icons.close : Icons.arrow_back),
                          ),
                        ),
                      if (!selecting)
                        Positioned(right: 16, child: SyncIndicator(size: 12)),
                    ],
                  ),
                ),
              Expanded(
                child: Obx(() {
                  final items = controller.showDeletedMessages
                      ? controller.deletedChats
                      : chats.chats
                          .archivedHelper(controller.showArchivedChats)
                          .unknownSendersHelper(controller.showUnknownSenders);
                  final loading = !chats.loadedChatBatch.value;

                  if (loading || items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loading
                                  ? 'Loading messages…'
                                  : controller.showArchivedChats
                                      ? 'No archived messages'
                                      : controller.showUnknownSenders
                                          ? 'No unknown senders'
                                          : controller.showDeletedMessages
                                              ? 'No deleted messages'
                                              : 'No messages yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 21,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (loading) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: foreground,
                                  strokeWidth: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller.materialScrollController,
                    physics: ThemeSwitcher.getScrollPhysics(),
                    padding: EdgeInsets.zero,
                    findChildIndexCallback: (key) =>
                        findChildIndexByKey(items, key, (item) => item.guid),
                    itemCount: items.length,
                    itemBuilder: (context, index) => KeyedSubtree(
                      key: ValueKey(items[index].guid),
                      child: ListItem(
                        chat: items[index],
                        controller: controller,
                        showDeleted: controller.showDeletedMessages,
                        autofocus: index == 0,
                        update: () => setState(() {}),
                      ),
                    ),
                  );
                }),
              ),
              Container(
                height: 54,
                decoration: BoxDecoration(border: Border(top: border)),
                child: selecting
                    ? _selectionActions(context)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _action('SEARCH', () => goToSearch(context)),
                          ),
                          VerticalDivider(
                              width: 1, thickness: 0.5, color: foreground),
                          Expanded(
                            child: _action(
                              'NEW',
                              () => controller.openNewChatCreator(context),
                              focusNode: controller.newMessageFocusNode,
                            ),
                          ),
                          VerticalDivider(
                              width: 1, thickness: 0.5, color: foreground),
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                OverflowMenu(controller: controller),
                                if (!isSubpage)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: IgnorePointer(
                                      child: SyncIndicator(size: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(String label, VoidCallback onPressed, {FocusNode? focusNode}) {
    return TextButton(
      focusNode: focusNode,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: Theme.of(context)
            .textTheme
            .labelLarge!
            .copyWith(fontSize: 15, fontWeight: FontWeight.w400),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    );
  }

  Widget _selectionActions(BuildContext context) {
    final selected = controller.selectedChats;
    final markUnread =
        selected.every((chat) => !(chat.hasUnreadMessage ?? false));
    final mute = selected.any((chat) => chat.muteType != 'mute');
    final pin = selected.any((chat) => !(chat.isPinned ?? false));
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _action(markUnread ? 'UNREAD' : 'READ', () {
            applyToSelection((chat) => chat.toggleHasUnread(markUnread));
          }),
        ),
        VerticalDivider(width: 1, thickness: 0.5, color: foreground),
        Expanded(
          child: _action(controller.showArchivedChats ? 'UNARCHIVE' : 'ARCHIVE',
              () {
            applyToSelection(
                (chat) => chat.toggleArchived(!controller.showArchivedChats));
          }),
        ),
        VerticalDivider(width: 1, thickness: 0.5, color: foreground),
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: 'More actions',
            shape: RoundedRectangleBorder(
                side: BorderSide(color: foreground, width: 0.5)),
            onSelected: (value) {
              if (value == 'mute') {
                applyToSelection((chat) => chat.toggleMute(mute));
              } else if (value == 'pin') {
                applyToSelection((chat) => chat.togglePin(pin));
              } else if (value == 'delete') {
                applyToSelection((chat) {
                  chats.removeChat(chat);
                  Chat.softDelete(chat);
                });
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'mute', child: Text(mute ? 'Mute' : 'Unmute')),
              PopupMenuItem(value: 'pin', child: Text(pin ? 'Pin' : 'Unpin')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            child: const Center(
              child: Text('MORE',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400)),
            ),
          ),
        ),
      ],
    );
  }
}
