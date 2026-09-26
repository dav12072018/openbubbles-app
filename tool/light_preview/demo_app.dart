import 'dart:async';

import 'package:flutter/material.dart';

import '../../lib/app/components/light/light_composer_viewport.dart';
import '../../lib/app/components/light/light_conversation_row.dart';
import '../../lib/app/components/light/light_message_surface.dart';
import '../../lib/app/components/light/light_message_sender.dart';
import '../../lib/app/components/light/light_theme.dart';
import 'voice/voice_factory.dart';

/// Standalone, in-memory UI demo. It has no messaging or account services.
class LightDemoApp extends StatefulWidget {
  const LightDemoApp({super.key, this.voiceCapture});
  final LocalVoiceCapture? voiceCapture;

  @override
  State<LightDemoApp> createState() => _LightDemoAppState();
}

class _LightDemoAppState extends State<LightDemoApp> {
  Brightness brightness = Brightness.dark;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OpenBubbles Light — local demo',
        debugShowCheckedModeBanner: false,
        theme: createLightPhoneTheme(brightness),
        home: _DemoHome(
          voiceCapture: widget.voiceCapture,
          brightness: brightness,
          toggleBrightness: () => setState(() => brightness =
              brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark),
        ),
      );
}

class _DemoMessage {
  const _DemoMessage(this.text, {this.fromMe = false, this.sender, this.voice});
  final String text;
  final bool fromMe;
  final String? sender;
  final LocalVoiceClip? voice;
}

class _DemoThread {
  _DemoThread(this.name, this.messages,
      {this.unread = false,
      this.pinned = false,
      this.muted = false,
      this.isGroup = false});
  final String name;
  final List<_DemoMessage> messages;
  bool unread;
  final bool pinned;
  final bool muted;
  final bool isGroup;
}

List<_DemoThread> _sampleThreads() => [
      _DemoThread(
          'Alex Morgan',
          [
            const _DemoMessage('Want to take the long way home?'),
            const _DemoMessage('Yes. Let’s meet by the park.', fromMe: true),
            const _DemoMessage('Meet you at the trailhead.'),
          ],
          unread: true),
      _DemoThread(
          'Saturday walk',
          [
            const _DemoMessage('I can bring coffee.', sender: 'Jamie'),
            const _DemoMessage('I’ll bring the cups.', sender: 'Morgan'),
            const _DemoMessage('See you both at nine.', fromMe: true),
          ],
          pinned: true,
          isGroup: true),
      _DemoThread('Sam Rivera', [
        const _DemoMessage('Are you free tomorrow?'),
        const _DemoMessage('Sounds good, see you then.', fromMe: true),
      ]),
      _DemoThread(
          'Neighborhood garden',
          [
            const _DemoMessage('The tomatoes are ready to pick.',
                sender: 'Riley'),
          ],
          muted: true,
          isGroup: true),
      _DemoThread('Taylor', [const _DemoMessage('Thanks for the book!')]),
    ];

class _DemoHome extends StatefulWidget {
  const _DemoHome(
      {required this.brightness,
      required this.toggleBrightness,
      this.voiceCapture});
  final Brightness brightness;
  final VoidCallback toggleBrightness;
  final LocalVoiceCapture? voiceCapture;

  @override
  State<_DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<_DemoHome> {
  List<_DemoThread> threads = _sampleThreads();
  _DemoThread? selected;
  bool searching = false;
  String query = '';
  final draft = TextEditingController();
  final search = TextEditingController();
  final transcript = ScrollController();
  late final LocalVoiceCapture voiceCapture;
  bool voiceStarting = false;
  bool recording = false;
  bool voiceStopping = false;
  LocalVoiceClip? voiceDraft;
  LocalVoiceClip? playing;
  String? voiceError;
  int voiceSession = 0;
  final recordWatch = Stopwatch();
  Timer? recordingTimer;

  @override
  void initState() {
    super.initState();
    voiceCapture = widget.voiceCapture ?? createLocalVoiceCapture();
  }

  @override
  void dispose() {
    recordingTimer?.cancel();
    voiceCapture.dispose();
    draft.dispose();
    search.dispose();
    transcript.dispose();
    super.dispose();
  }

  void back() {
    discardVoice();
    FocusScope.of(context).unfocus();
    setState(() {
      selected = null;
      searching = false;
      query = '';
      draft.clear();
      search.clear();
    });
  }

  void openThread(_DemoThread thread) {
    discardVoice();
    FocusScope.of(context).unfocus();
    setState(() {
      selected = thread;
      thread.unread = false;
      draft.clear();
    });
    scrollToLatest();
  }

  void scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && transcript.hasClients) {
          transcript.jumpTo(transcript.position.maxScrollExtent);
        }
      });

  void sendLocally() {
    final text = draft.text.trim();
    if (text.isEmpty || selected == null) return;
    setState(() {
      selected!.messages.add(_DemoMessage(text, fromMe: true));
      draft.clear();
    });
    scrollToLatest();
  }

  String durationLabel(Duration duration) =>
      '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

  void discardVoice() {
    voiceSession++;
    recordingTimer?.cancel();
    recordWatch.stop();
    voiceCapture.cancel();
    voiceCapture.stopPlayback();
    voiceStarting = false;
    recording = false;
    voiceStopping = false;
    voiceDraft = null;
    playing = null;
    voiceError = null;
  }

  Future<void> startVoice() async {
    final session = ++voiceSession;
    FocusScope.of(context).unfocus();
    setState(() {
      voiceStarting = true;
      voiceError = null;
    });
    try {
      await voiceCapture.start();
      if (!mounted || session != voiceSession) return;
      recordWatch
        ..reset()
        ..start();
      setState(() {
        voiceStarting = false;
        recording = true;
      });
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && recording) setState(() {});
      });
    } catch (_) {
      if (!mounted || session != voiceSession) return;
      setState(() {
        voiceStarting = false;
        voiceError =
            'Microphone unavailable. Allow access in your browser and try again.';
      });
    }
  }

  Future<void> stopVoice() async {
    final session = voiceSession;
    recordingTimer?.cancel();
    recordWatch.stop();
    setState(() {
      recording = false;
      voiceStopping = true;
    });
    try {
      final clip = await voiceCapture.stop();
      if (!mounted || session != voiceSession) return;
      setState(() {
        voiceStopping = false;
        voiceDraft = clip;
      });
    } catch (_) {
      if (!mounted || session != voiceSession) return;
      setState(() {
        voiceStopping = false;
        voiceError = 'Could not save the recording. Please try again.';
      });
    }
  }

  Future<void> playVoice(LocalVoiceClip clip) async {
    if (identical(playing, clip)) {
      voiceCapture.stopPlayback();
      setState(() => playing = null);
      return;
    }
    setState(() {
      playing = clip;
      voiceError = null;
    });
    try {
      await voiceCapture.play(clip);
    } catch (_) {
      if (mounted && identical(playing, clip))
        setState(() => voiceError = 'Could not play this voice note.');
    } finally {
      if (mounted && identical(playing, clip)) setState(() => playing = null);
    }
  }

  void sendVoice() {
    final clip = voiceDraft;
    if (clip == null || selected == null) return;
    setState(() {
      selected!.messages
          .add(_DemoMessage('Voice note', fromMe: true, voice: clip));
      discardVoice();
    });
    scrollToLatest();
  }

  Widget voiceControls() {
    final clip = voiceDraft;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            recording
                ? 'Recording ${durationLabel(recordWatch.elapsed)}'
                : voiceStarting
                    ? 'Waiting for microphone…'
                    : voiceStopping
                        ? 'Saving voice note…'
                        : 'Voice note · ${durationLabel(clip!.duration)}',
            style: Theme.of(context).textTheme.bodySmall,
          )),
      Row(children: [
        if (clip != null)
          action(identical(playing, clip) ? 'STOP' : 'PLAY',
              () => playVoice(clip)),
        action('CANCEL', () => setState(discardVoice)),
        if (recording) action('STOP', stopVoice),
        if (clip != null) action('SEND', sendVoice),
      ]),
    ]);
  }

  String previewFor(_DemoThread thread) {
    if (thread.messages.isEmpty) return 'New conversation';
    final message = thread.messages.last;
    final sender = message.fromMe
        ? 'You'
        : thread.isGroup
            ? message.sender
            : null;
    return '${sender == null ? '' : '$sender: '}${message.text}';
  }

  Widget messageContent(_DemoMessage message) {
    final clip = message.voice;
    if (clip == null) return Text(message.text);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        tooltip:
            identical(playing, clip) ? 'Stop playback' : 'Play voice note',
        onPressed: () => playVoice(clip),
        icon: Icon(identical(playing, clip) ? Icons.stop : Icons.play_arrow),
      ),
      Flexible(child: Text('Voice note · ${durationLabel(clip.duration)}')),
    ]);
  }

  Widget composer() => Column(mainAxisSize: MainAxisSize.min, children: [
        if (voiceError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child:
                Text(voiceError!, style: Theme.of(context).textTheme.bodySmall),
          ),
        if (voiceStarting || recording || voiceStopping || voiceDraft != null)
          voiceControls()
        else
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
              tooltip: 'Demo attachments',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  scrollable: true,
                  title: const Text('Attachments'),
                  content: const Text(
                      'This local demo supports voice notes. File uploads are available in the full Android app.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('BACK'))
                  ],
                ),
              ),
              icon: const Icon(Icons.add),
            ),
            Expanded(
                child: TextField(
              key: const ValueKey('demo-draft'),
              controller: draft,
              minLines: 1,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Message'),
            )),
            SizedBox(
                width: 62,
                height: 48,
                child: draft.text.trim().isEmpty
                    ? IconButton(
                        tooltip: 'Record voice note',
                        onPressed: startVoice,
                        icon: const Icon(Icons.mic_none))
                    : TextButton(
                        onPressed: sendLocally,
                        child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child:
                                Text('SEND', style: TextStyle(fontSize: 14))))),
          ]),
      ]);

  Future<void> createThread() async {
    String name = '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('New demo conversation'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => name = value,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty)
              Navigator.pop(dialogContext, value.trim());
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL')),
          TextButton(
              onPressed: () {
                if (name.trim().isNotEmpty)
                  Navigator.pop(dialogContext, name.trim());
              },
              child: const Text('CREATE')),
        ],
      ),
    );
    if (!mounted || result == null) return;
    final thread = _DemoThread(result, []);
    setState(() => threads.insert(0, thread));
    openThread(thread);
  }

  void menu() => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                  'Local demo\nMessages stay here. Nothing is sent to anyone. Changes reset when you reload.',
                  textAlign: TextAlign.center),
            ),
            ListTile(
              title: Text(widget.brightness == Brightness.dark
                  ? 'Use light appearance'
                  : 'Use dark appearance'),
              onTap: () {
                Navigator.pop(sheetContext);
                widget.toggleBrightness();
              },
            ),
            ListTile(
                title: const Text('Reset sample conversations'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => threads = _sampleThreads());
                  back();
                }),
            ListTile(
                title: const Text('Back to demo'),
                onTap: () => Navigator.pop(sheetContext)),
          ])),
        ),
      );

  Widget action(String label, VoidCallback callback) => Expanded(
        child: TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle:
                Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 15),
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thread = selected;
    final filtered = threads
        .where((item) =>
            '${item.name} ${item.messages.map((message) => message.text).join(' ')}'
                .toLowerCase()
                .contains(query.toLowerCase()))
        .toList();
    return PopScope(
      canPop: selected == null && !searching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: thread == null ? 48 : 56,
          leading: thread != null || searching
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: back,
                  icon: const Icon(Icons.arrow_back))
              : null,
          title: Text(thread?.name ?? 'Messages',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: thread != null
              ? [
                  IconButton(
                      tooltip: 'Menu',
                      onPressed: menu,
                      icon: const Icon(Icons.more_vert))
                ]
              : null,
        ),
        body: LayoutBuilder(
            builder: (context, constraints) => Column(children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    child: Text('LOCAL DEMO · NO REAL SENDS',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall),
                  ),
                  if (thread == null && searching)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: TextField(
                          key: const ValueKey('demo-search'),
                          controller: search,
                          autofocus: true,
                          decoration: const InputDecoration(
                              hintText: 'Search conversations'),
                          onChanged: (value) => setState(() => query = value),
                        )),
                  Expanded(
                      child: thread == null
                          ? (filtered.isEmpty
                              ? const Center(
                                  child: Text('No conversations found.'))
                              : ListView(children: [
                                  for (final item in filtered)
                                    LightConversationRow(
                                      title: Text(item.name),
                                      preview: Text(previewFor(item)),
                                      timestamp:
                                          item.messages.isEmpty ? '' : 'Today',
                                      unread: item.unread,
                                      pinned: item.pinned,
                                      muted: item.muted,
                                      onTap: () => openThread(item),
                                    ),
                                ]))
                          : (thread.messages.isEmpty
                              ? const Center(
                                  child: Text('Write a message to try it.'))
                              : ListView(
                                  controller: transcript,
                                  padding: const EdgeInsets.all(18),
                                  children: [
                                    for (final message in thread.messages)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 18),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (thread.isGroup ||
                                                  message.fromMe)
                                                LightMessageSender(
                                                    name: message.fromMe
                                                        ? 'You'
                                                        : message.sender ??
                                                            thread.name),
                                              LightMessageSurface(
                                                isFromMe: message.fromMe,
                                                constraints: BoxConstraints(
                                                    maxWidth:
                                                        constraints.maxWidth -
                                                            36),
                                                child: messageContent(message),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                  ],
                                ))),
                  if (thread != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight:
                              (constraints.maxHeight * 0.65).clamp(48, 300)),
                      child: LightComposerViewport(
                          child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: composer(),
                              ))),
                    ),
                ])),
        bottomNavigationBar: thread != null
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: theme.colorScheme.onSurface, width: 0.5))),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        action(
                            'SEARCH', () => setState(() => searching = true)),
                        VerticalDivider(
                            width: 1,
                            thickness: 0.5,
                            color: theme.colorScheme.onSurface),
                        action('NEW', createThread),
                        VerticalDivider(
                            width: 1,
                            thickness: 0.5,
                            color: theme.colorScheme.onSurface),
                        action('MENU', menu),
                      ]),
                )),
      ),
    );
  }
}
