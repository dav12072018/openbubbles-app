import 'package:flutter/material.dart';

import '../../../lib/app/components/light/light_conversation_row.dart';
import '../../../lib/app/components/light/light_message_surface.dart';
import '../../../lib/app/components/light/light_message_sender.dart';
import '../../../lib/app/components/light/light_voice_note_controls.dart';
import '../../../lib/app/components/light/light_theme.dart';

void main() => runApp(const LightComponentPreview());

/// A component lab with explicit fixture data, not the running messaging app.
class LightComponentPreview extends StatelessWidget {
  const LightComponentPreview({
    super.key,
    this.brightness = Brightness.dark,
    this.textScale = 1,
    this.captureKey,
    this.conversation = false,
  });

  final Brightness brightness;
  final double textScale;
  final GlobalKey? captureKey;
  final bool conversation;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: createLightPhoneTheme(brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: RepaintBoundary(
          key: captureKey,
          child: conversation
              ? const _FixtureConversation()
              : const _FixtureInbox(),
        ),
      );
}

class _FixtureInbox extends StatelessWidget {
  const _FixtureInbox();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          title: const Text('Messages'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                'COMPONENT PREVIEW · SAMPLE DATA',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Expanded(
              child: ListView(
                children: const [
                  LightConversationRow(
                    title: Text('Alex Morgan'),
                    preview: Text('Meet you at the trailhead.'),
                    timestamp: '10:42',
                    unread: true,
                  ),
                  LightConversationRow(
                    title: Text('Saturday walk'),
                    preview: Text('Jamie: I can bring coffee.'),
                    timestamp: '9:15',
                    pinned: true,
                  ),
                  LightConversationRow(
                    title: Text('Sam Rivera'),
                    preview: Text('You: Sounds good, see you then.'),
                    timestamp: 'Yesterday',
                    deliveryStatus: 'Read',
                  ),
                  LightConversationRow(
                    title: Text('Neighborhood garden'),
                    preview: Text('The tomatoes are ready to pick.'),
                    timestamp: 'Tue',
                    muted: true,
                  ),
                  LightConversationRow(
                    title: Text('Taylor'),
                    preview: Text('Thanks for the book!'),
                    timestamp: 'Mon',
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 0.5))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final label in ['SEARCH', 'NEW', 'MENU']) ...[
                  if (label != 'SEARCH')
                    VerticalDivider(
                        width: 1,
                        thickness: 0.5,
                        color: Theme.of(context).colorScheme.onSurface),
                  Expanded(
                      child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                    ),
                    child: FittedBox(
                        fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
                  )),
                ],
              ],
            ),
          ),
        ),
      );
}

class _FixtureConversation extends StatelessWidget {
  const _FixtureConversation();

  @override
  Widget build(BuildContext context) {
    Widget message(String text, {required bool fromMe}) => Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fromMe) const LightMessageSender(name: 'You'),
                LightMessageSurface(
                  isFromMe: fromMe,
                  constraints: const BoxConstraints(maxWidth: 324),
                  child: Text(text),
                ),
              ],
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Alex Morgan'),
        leading: IconButton(
          tooltip: 'Preview back',
          onPressed: () {},
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
              tooltip: 'Preview more',
              onPressed: () {},
              icon: const Icon(Icons.more_vert))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              'COMPONENT PREVIEW · SAMPLE DATA',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              children: [
                Center(
                    child: Text('TODAY · 10:42',
                        style: Theme.of(context).textTheme.labelSmall)),
                const SizedBox(height: 22),
                message('Want to take the long way home?', fromMe: false),
                message('Yes. Let’s meet by the park.', fromMe: true),
                message('I’ll bring coffee.', fromMe: false),
                message('Perfect. See you soon.', fromMe: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Delivered',
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                  tooltip: 'Preview attachment',
                  onPressed: () {},
                  icon: const Icon(Icons.add)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Message',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              LightVoiceNoteControls(
                recording: false,
                onRecord: () {},
                onStop: () {},
                onCancel: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
