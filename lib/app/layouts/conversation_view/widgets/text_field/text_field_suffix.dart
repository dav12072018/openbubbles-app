import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:bluebubbles/app/components/light/light_voice_note_controls.dart';
import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/effects/send_effect_picker.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/attachment/audio_player.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/send_button.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/conversation_text_field.dart';
import 'package:bluebubbles/app/wrappers/cupertino_icon_wrapper.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:path/path.dart' hide context;
import 'package:record/record.dart';
import 'package:system_info2/system_info2.dart';
import 'package:universal_io/io.dart';

class TextFieldSuffix extends StatefulWidget {
  const TextFieldSuffix({
    super.key,
    required this.subjectTextController,
    required this.textController,
    required this.controller,
    required this.recorderController,
    required this.sendMessage,
    this.isChatCreator = false,
  });

  final TextEditingController? subjectTextController;
  final TextEditingController textController;
  final ConversationViewController? controller;
  final RecorderController? recorderController;
  final Future<void> Function({String? effect}) sendMessage;
  final bool isChatCreator;

  @override
  OptimizedState createState() => _TextFieldSuffixState();
}

class _TextFieldSuffixState extends OptimizedState<TextFieldSuffix> {

  bool get isChatCreator => widget.isChatCreator;
  bool lightRecordingBusy = false;
  bool lightDesktopRecorderCreated = false;

  @override
  void dispose() {
    if (lightDesktopRecorderCreated) {
      final recorderId = widget.controller!.chat.guid;
      // The desktop backend is separate from RecorderController. Tear it down
      // even if the surrounding composer has already cleared showRecording.
      unawaited(() async {
        try {
          final path = await RecordPlatform.instance.stop(recorderId);
          if (path != null && await File(path).exists()) await File(path).delete();
        } finally {
          await RecordPlatform.instance.dispose(recorderId);
        }
      }().catchError((_) {}));
    }
    super.dispose();
  }

  Future<void> lightRecordingAction({bool cancel = false}) async {
    final conversation = widget.controller;
    if (conversation == null || kIsWeb || lightRecordingBusy) return;
    lightRecordingBusy = true;
    setState(() {});
    try {
      if (!conversation.showRecording.value) {
        // Recording only begins in response to an explicit microphone tap.
        FocusScope.of(context).unfocus();
        conversation.showAttachmentPicker = false;
        conversation.updateWidgets<ConversationTextField>(null);
        if (kIsDesktop) {
          if (!lightDesktopRecorderCreated) {
            await RecordPlatform.instance.create(conversation.chat.guid);
            lightDesktopRecorderCreated = true;
          }
          if (!mounted) {
            await RecordPlatform.instance.dispose(conversation.chat.guid);
            return;
          }
          if (!await RecordPlatform.instance.hasPermission(conversation.chat.guid)) {
            showSnackbar('Microphone access needed', 'Allow microphone access to record a voice note.');
            return;
          }
          if (!mounted) return;
          final file = File(join(fs.appDocDir.path, 'temp', 'recorder',
              'voice-${DateTime.now().microsecondsSinceEpoch}.m4a'));
          await file.parent.create(recursive: true);
          await RecordPlatform.instance.start(conversation.chat.guid,
              const RecordConfig(bitRate: 320000), path: file.path);
        } else {
          final recorder = widget.recorderController;
          if (recorder == null) return;
          await recorder.record(recorderSettings: const RecorderSettings(
            sampleRate: 44100, bitRate: 320000,
          ));
          if (!recorder.isRecording) {
            showSnackbar('Microphone access needed', 'Allow microphone access to record a voice note.');
            return;
          }
        }
        if (!mounted) {
          final path = kIsDesktop
              ? await RecordPlatform.instance.stop(conversation.chat.guid)
              : await widget.recorderController?.stop();
          if (path != null) await File(path).delete();
          return;
        }
        conversation.showRecording.value = true;
      } else {
        final path = kIsDesktop
            ? await RecordPlatform.instance.stop(conversation.chat.guid)
            : await widget.recorderController?.stop();
        conversation.showRecording.value = false;
        if (path == null) {
          if (!cancel) showSnackbar('Recording unavailable', 'Please try recording your voice note again.');
          return;
        }
        final recording = File(path);
        try {
          if (cancel || !mounted) return;
          final bytes = await recording.readAsBytes();
          if (bytes.isEmpty) {
            showSnackbar('Recording empty', 'Please try recording your voice note again.');
            return;
          }
          final previewFile = PlatformFile(name: basename(path), path: path,
              bytes: bytes, size: bytes.length);
          if (!mounted) return;
          final previewRoute = DialogRoute<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              scrollable: true,
              title: const Text('Voice note'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Listen before sending.'),
                  const SizedBox(height: 12),
                  AudioPlayer(file: previewFile, attachment: null),
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('DISCARD')),
                TextButton(onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('SEND')),
              ],
            ),
          );
          final send = await Navigator.of(context).push(previewRoute);
          // The pop result precedes the closing animation. Wait for removal
          // and widget disposal before cleaning up the player's source file.
          await previewRoute.completed;
          await WidgetsBinding.instance.endOfFrame;
          if (send == true && mounted) {
            // Queue the captured bytes rather than a temporary file path, so
            // the original recording can be removed after the preview closes.
            await conversation.send([
              PlatformFile(name: previewFile.name, bytes: bytes, size: bytes.length),
            ], AttributedBody.empty(), '', null, null, null, null, true, null);
          }
        } finally {
          if (await recording.exists()) await recording.delete();
        }
      }
    } catch (_) {
      // A native start/stop failure must never leave capture running behind
      // an idle-looking composer.
      try {
        final path = kIsDesktop
            ? await RecordPlatform.instance.stop(conversation.chat.guid)
            : await widget.recorderController?.stop();
        if (path != null && await File(path).exists()) await File(path).delete();
      } catch (_) {}
      conversation.showRecording.value = false;
      if (mounted) showSnackbar('Voice note unavailable', 'Could not record the voice note. Check microphone access and try again.');
    } finally {
      lightRecordingBusy = false;
      if (mounted) setState(() {});
    }
  }

  void showSendOptions() {
    if (isChatCreator) return;
    if (widget.controller!.scheduledDate.value != null || !widget.controller!.chat.isIMessage) return;
    sendEffectAction(
      context,
      widget.controller!,
      widget.textController is MentionTextEditingController ? (widget.textController as MentionTextEditingController).getFinalAnnotations() : AttributedBody.raw(widget.textController.text),
      widget.subjectTextController?.text.trim() ?? '',
      widget.controller!.replyToMessage?.item1.guid,
      widget.controller!.replyToMessage?.item2,
      widget.controller!.chat.guid,
      widget.sendMessage,
      widget.controller!.scheduledDate.value,
    );
  }

  void deleteAudioRecording(String path) {
    File(path).delete();
  }

  Future<void> toggleRecording(BuildContext context) async {
    if (widget.controller == null) return;
    widget.controller!.showRecording.toggle();
    if (widget.controller!.showRecording.value) {
      if (kIsDesktop) {
        File temp = File(join(fs.appDocDir.path, "temp", "recorder", "${widget.controller!.chat.guid.characters.where((c) => c.isAlphabetOnly || c.isNumericOnly).join()}.m4a"));
        await RecordPlatform.instance.start(widget.controller!.chat.guid, const RecordConfig(bitRate: 320000), path: temp.path);
        return;
      }
      await widget.recorderController!.record(
        recorderSettings: const RecorderSettings(
          sampleRate: 44100,
          bitRate: 320000,
        )
      );
      } else {
      late final String? path;
      late final PlatformFile file;
      final previewFocusNode = FocusNode();
      final discardFocusNode = FocusNode();
      final sendFocusNode = FocusNode();
      if (kIsDesktop) {
        path = await RecordPlatform.instance.stop(widget.controller!.chat.guid);
        if (path == null) return;
        final _file = File(path);
        file = PlatformFile(
          name: basename(_file.path),
          path: _file.path,
          bytes: await _file.readAsBytes(),
          size: await _file.length(),
        );
      } else {
        path = await widget.recorderController!.stop();
        if (path == null) return;
        final _file = File(path);
        file = PlatformFile(
          name: basename(_file.path),
          path: _file.path,
          bytes: await _file.readAsBytes(),
          size: await _file.length(),
        );
      }
      try {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (previewFocusNode.canRequestFocus) {
                previewFocusNode.requestFocus();
              }
            });
            final focusedBackground = context.theme.colorScheme.outline.withOpacity(0.2);
            return AlertDialog(
              backgroundColor: context.theme.colorScheme.properSurface,
              title: Text("Send it?", style: context.theme.textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Review your audio snippet before sending it", style: context.theme.textTheme.bodyLarge),
                  Container(height: 10.0),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.width * 0.6),
                    child: AudioPlayer(
                      key: Key("AudioMessage-$path"),
                      file: file,
                      attachment: null,
                      playButtonFocusNode: previewFocusNode,
                      nextFocusNode: discardFocusNode,
                    ),
                  )
                ],
              ),
              actions: <Widget>[
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () => previewFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () => previewFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.arrowRight): () => sendFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.arrowDown): () => sendFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.enter): () {
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                    const SingleActivator(LogicalKeyboardKey.select): () {
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                    const SingleActivator(LogicalKeyboardKey.space): () {
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                  },
                  child: TextButton(
                    focusNode: discardFocusNode,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.focused) ? focusedBackground : null),
                    ),
                    child: Text(
                        "Discard",
                        style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)
                    ),
                    onPressed: () {
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                  ),
                ),
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () => discardFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.arrowUp): () => discardFocusNode.requestFocus(),
                    const SingleActivator(LogicalKeyboardKey.enter): () async {
                      await widget.controller!.send(
                        [file],
                        AttributedBody.empty(), "", null, null, null, null, true, null
                      );
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                    const SingleActivator(LogicalKeyboardKey.select): () async {
                      await widget.controller!.send(
                        [file],
                        AttributedBody.empty(), "", null, null, null, null, true, null
                      );
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                    const SingleActivator(LogicalKeyboardKey.space): () async {
                      await widget.controller!.send(
                        [file],
                        AttributedBody.empty(), "", null, null, null, null, true, null
                      );
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                  },
                  child: TextButton(
                    focusNode: sendFocusNode,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.focused) ? focusedBackground : null),
                    ),
                    child: Text(
                        "Send",
                        style: context.theme.textTheme.bodyLarge!.copyWith(color: Get.context!.theme.colorScheme.primary)
                    ),
                    onPressed: () async {
                      await widget.controller!.send(
                        [file],
                        AttributedBody.empty(), "", null, null, null, null, true, null
                      );
                      deleteAudioRecording(file.path!);
                      Get.back();
                    },
                  ),
                ),
              ],
            );
          },
        );
      } finally {
        previewFocusNode.dispose();
        discardFocusNode.dispose();
        sendFocusNode.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      valueListenables: [widget.textController, widget.subjectTextController].whereNotNull().toList(),
      builder: (context, values, _) {
        return Obx(() {
          bool canSend = widget.textController.text.isNotEmpty ||
              (widget.subjectTextController?.text.isNotEmpty ?? false) ||
              widget.controller?.pickedApp.value != null ||
              (widget.controller?.pickedAttachments.isNotEmpty ?? false.obs.value);
          bool showRecording = (widget.controller?.showRecording.value ?? false.obs.value) && widget.recorderController != null;
          bool isLinuxArm64 = kIsDesktop && Platform.isLinux && SysInfo.kernelArchitecture == ProcessorArchitecture.arm64;
          if (ss.settings.skin.value == Skins.Light) {
            final lightCanSend = widget.textController.text.trim().isNotEmpty ||
                (widget.subjectTextController?.text.trim().isNotEmpty ?? false) ||
                widget.controller?.pickedApp.value != null ||
                (widget.controller?.pickedAttachments.isNotEmpty ?? false);
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: (lightCanSend || isChatCreator) && !showRecording
                  ? SendButton(sendMessage: widget.sendMessage,
                      previousFocusNode: widget.controller?.lastFocusedNode,
                      onLongPress: showSendOptions)
                  : LightVoiceNoteControls(
                      recording: showRecording,
                      busy: lightRecordingBusy || kIsWeb || isLinuxArm64,
                      onRecord: lightRecordingAction,
                      onStop: lightRecordingAction,
                      onCancel: () => lightRecordingAction(cancel: true),
                    ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(3.0),
            child: AnimatedCrossFade(
              crossFadeState: (canSend || isChatCreator) && !showRecording
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 150),
              firstChild: kIsWeb ? const SizedBox(height: 32, width: 32) : CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                    widget.controller?.lastFocusedNode.requestFocus();
                  },
                  const SingleActivator(LogicalKeyboardKey.enter): () {
                    toggleRecording(context);
                  },
                  const SingleActivator(LogicalKeyboardKey.select): () {
                    toggleRecording(context);
                  },
                  const SingleActivator(LogicalKeyboardKey.space): () {
                    toggleRecording(context);
                  },
                },
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: !iOS || (iOS && !isChatCreator && !showRecording)
                        ? null
                        : !isChatCreator && !showRecording
                        ? context.theme.colorScheme.outline
                        : context.theme.colorScheme.primary.withOpacity(0.4),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(0),
                    maximumSize: kIsDesktop ? const Size(40, 40) : const Size(32, 32),
                    minimumSize: kIsDesktop ? const Size(40, 40) : const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isLinuxArm64 ? const SizedBox(height: 40) :
                    !isChatCreator && !showRecording
                    ? CupertinoIconWrapper(icon: Icon(
                      iOS ? CupertinoIcons.waveform : Icons.mic_none,
                      color: iOS ? context.theme.colorScheme.outline : context.theme.colorScheme.properOnSurface,
                      size: iOS ? 24 : 20, // Waveform icon appears smaller, using size 24
                    )) : CupertinoIconWrapper(icon: Icon(
                      iOS ? CupertinoIcons.stop_fill : Icons.stop_circle,
                      color: iOS ? context.theme.colorScheme.primary : context.theme.colorScheme.properOnSurface,
                      size: 15,
                    )),
                  onPressed: () async => toggleRecording(context),
                ),
              ),
              secondChild: SendButton(
                sendMessage: widget.sendMessage,
                previousFocusNode: widget.controller?.lastFocusedNode,
                onLongPress: isChatCreator ? () {} : () {
                  if (widget.controller!.scheduledDate.value != null || !widget.controller!.chat.isIMessage) return;
                  sendEffectAction(
                    context,
                    widget.controller!,
                    widget.textController is MentionTextEditingController ? (widget.textController as MentionTextEditingController).getFinalAnnotations() : AttributedBody.raw(widget.textController.text),
                    widget.subjectTextController?.text.trim() ?? "",
                    widget.controller!.replyToMessage?.item1.guid,
                    widget.controller!.replyToMessage?.item2,
                    widget.controller!.chat.guid,
                    widget.sendMessage,
                    widget.controller!.scheduledDate.value,
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }
}
