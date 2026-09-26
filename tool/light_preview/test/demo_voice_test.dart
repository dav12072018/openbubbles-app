import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_message_sender.dart';
import '../../../lib/app/components/light/light_message_surface.dart';
import '../../../lib/app/components/light/light_voice_note_controls.dart';
import '../demo_app.dart';
import '../voice/voice_capture.dart';

class FakeVoiceCapture implements LocalVoiceCapture {
  int starts = 0;
  int stops = 0;
  int cancels = 0;
  int plays = 0;
  bool failStart = false;
  Completer<void>? permission;
  Completer<void>? playback;
  final clip = LocalVoiceClip(
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'audio/webm',
      duration: const Duration(seconds: 3));

  @override
  Future<void> start() async {
    starts++;
    if (failStart) throw StateError('Permission denied');
    await permission?.future;
  }

  @override
  Future<LocalVoiceClip> stop() async {
    stops++;
    return clip;
  }

  @override
  void cancel() {
    cancels++;
  }

  @override
  Future<void> play(LocalVoiceClip clip) {
    plays++;
    playback = Completer<void>();
    return playback!.future;
  }

  @override
  void stopPlayback() {
    if (playback != null && !playback!.isCompleted) playback!.complete();
  }

  @override
  void dispose() {
    cancel();
    stopPlayback();
  }
}

Future<void> openDemo(WidgetTester tester, FakeVoiceCapture capture) async {
  tester.view.physicalSize = const Size(360, 413);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(LightDemoApp(voiceCapture: capture));
  await tester.tap(find.text('Alex Morgan'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('local record, stop, review, play, send and replay at LP3 size',
      (tester) async {
    final capture = FakeVoiceCapture();
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openDemo(tester, capture);
    expect(capture.starts, 0);
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('demo-draft')), 'Hello');
    await tester.pump();
    expect(find.byTooltip('Record voice note'), findsNothing);
    expect(find.text('SEND'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('demo-draft')), '  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Record voice note'));
    await tester.pumpAndSettle();
    expect(capture.starts, 1);
    expect(find.text('STOP'), findsOneWidget);
    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    expect(capture.stops, 1);
    expect(find.text('Voice note · 00:03'), findsOneWidget);
    expect(tester.getBottomRight(find.text('SEND')).dy, lessThanOrEqualTo(413));
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(capture.plays, 1);
    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    expect(find.text('Voice note · 00:03'), findsOneWidget);
    final voiceSurface = find.ancestor(
        of: find.text('Voice note · 00:03'),
        matching: find.byType(LightMessageSurface));
    expect(tester.getRect(voiceSurface).right, closeTo(342, 0.01));
    expect(tester.getRect(find.text('You').last).right, closeTo(342, 0.01));
    await tester.tap(find.byTooltip('Play voice note'));
    await tester.pumpAndSettle();
    expect(capture.plays, 2);
    await tester.tap(find.byTooltip('Stop playback'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('You: Voice note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel recording and review; denied or late permission recovers',
      (tester) async {
    final capture = FakeVoiceCapture();
    await openDemo(tester, capture);
    await tester.tap(find.byTooltip('Record voice note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    expect(capture.stops, 0);
    await tester.tap(find.byTooltip('Record voice note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(find.text('Voice note · 00:03'), findsNothing);
    capture.failStart = true;
    await tester.tap(find.byTooltip('Record voice note'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Microphone unavailable.'), findsOneWidget);
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    capture.failStart = false;
    capture.permission = Completer<void>();
    await tester.tap(find.byTooltip('Record voice note'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for microphone…'), findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    capture.permission!.complete();
    await tester.pumpAndSettle();
    expect(find.text('STOP'), findsNothing);
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'group sender captions stay with incoming left and sent right messages',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(LightDemoApp(voiceCapture: FakeVoiceCapture()));
    await tester.tap(find.text('Saturday walk'));
    await tester.pumpAndSettle();
    expect(find.byType(LightMessageSender), findsNWidgets(3));
    for (final name in ['Jamie', 'Morgan', 'You']) {
      final caption = tester.widget<Text>(find.text(name));
      expect(caption.style!.fontSize, 14);
    }
    expect(tester.getRect(find.text('I can bring coffee.')).left,
        closeTo(18, 0.01));
    expect(tester.getRect(find.text('I’ll bring the cups.')).left,
        closeTo(18, 0.01));
    expect(tester.getRect(find.text('Jamie')).left, closeTo(18, 0.01));
    expect(tester.getRect(find.text('Morgan')).left, closeTo(18, 0.01));
    expect(tester.getRect(find.text('See you both at nine.')).right,
        closeTo(342, 0.01));
    expect(tester.getRect(find.text('You')).right, closeTo(342, 0.01));
    expect(find.text('Jamie: I can bring coffee.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final thread in ['Alex Morgan', 'Saturday walk']) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          '$thread newly sent wrapped text and You caption align right at ${scale}x',
          (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(LightDemoApp(voiceCapture: FakeVoiceCapture()));
        await tester.tap(find.text(thread));
        await tester.pumpAndSettle();
        final incoming = thread == 'Alex Morgan'
            ? 'Meet you at the trailhead.'
            : 'I’ll bring the cups.';
        expect(tester.getRect(find.text(incoming)).left, closeTo(18, 0.01));
        const message =
            'I will meet you by the park after work and bring the map for our walk. See you soon.';
        await tester.enterText(
            find.byKey(const ValueKey('demo-draft')), message);
        await tester.pump();
        await tester.tap(find.text('SEND'));
        await tester.pumpAndSettle();
        final paragraph =
            tester.renderObject<RenderParagraph>(find.text(message));
        final lines = paragraph.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: message.length));
        expect(lines.length, greaterThan(1));
        expect(paragraph.textAlign, TextAlign.right);
        expect(tester.getRect(find.text(message)).right, closeTo(342, 0.01));
        expect(
            paragraph
                .localToGlobal(Offset(lines.last.right, lines.last.bottom))
                .dx,
            closeTo(342, 0.01));
        expect(tester.getRect(find.text('You').last).right, closeTo(342, 0.01));
        expect(tester.getBottomLeft(find.text('You').last).dy,
            lessThan(tester.getTopLeft(find.text(message)).dy));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'native Light voice controls retain compact reachable callbacks at 1.6x',
      (tester) async {
    int records = 0, stops = 0, cancels = 0;
    Widget controls(bool recording, {bool busy = false}) => MaterialApp(
            home: Scaffold(
                body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                  width: 104,
                  child: LightVoiceNoteControls(
                    recording: recording,
                    busy: busy,
                    onRecord: () => records++,
                    onStop: () => stops++,
                    onCancel: () => cancels++,
                  ))),
        )));
    await tester.pumpWidget(controls(false));
    await tester.tap(find.byTooltip('Record voice note'));
    expect(records, 1);
    await tester.pumpWidget(controls(true));
    await tester.tap(find.byTooltip('Cancel voice note'));
    await tester.tap(find.text('STOP'));
    expect(cancels, 1);
    expect(stops, 1);
    await tester.pumpWidget(controls(true, busy: true));
    await tester.tap(find.text('STOP'));
    expect(stops, 1);
    expect(tester.takeException(), isNull);
  });
}
