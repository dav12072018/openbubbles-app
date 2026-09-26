import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_conversation_row.dart';
import '../../../lib/app/components/light/light_composer_viewport.dart';
import '../../../lib/app/components/light/light_message_surface.dart';
import '../../../lib/app/components/light/light_message_sender.dart';
import '../../../lib/app/components/light/light_theme.dart';
import 'preview_app.dart';

Future<void> loadPreviewFonts() async {
  final font = FontLoader('Inter')
    ..addFont(File('../../assets/fonts/Inter-VariableFont_opsz,wght.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.sublistView(bytes)));
  await font.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

double contrast(Color first, Color second) {
  final a = first.computeLuminance();
  final b = second.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadPreviewFonts);

  for (final brightness in Brightness.values) {
    test('${brightness.name} text and action colors have accessible contrast',
        () {
      final theme = createLightPhoneTheme(brightness);
      final colors = theme.colorScheme;
      expect(
          contrast(
              theme.textTheme.bodyLarge!.color!, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(7));
      expect(
          contrast(colors.onSurface, colors.surface), greaterThanOrEqualTo(7));
      expect(contrast(colors.onSurfaceVariant, colors.surface),
          greaterThanOrEqualTo(4.5));
      expect(
          contrast(colors.onPrimary, colors.primary), greaterThanOrEqualTo(7));
      expect(
          contrast(
              theme.textTheme.bodySmall!.color!, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5));
      for (final color in [
        colors.primary,
        colors.secondary,
        colors.tertiary,
        theme.scaffoldBackgroundColor,
        colors.surface
      ]) {
        expect(color.red, color.green);
        expect(color.green, color.blue);
      }
    });
  }

  for (final height in [413.0, 800.0]) {
    for (final scale in [1.0, 1.6]) {
      for (final brightness in Brightness.values) {
        testWidgets(
            '360x$height, text $scale, ${brightness.name}: fits and scrolls',
            (tester) async {
          tester.view.physicalSize = Size(360, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
              LightComponentPreview(brightness: brightness, textScale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('COMPONENT PREVIEW · SAMPLE DATA'), findsOneWidget);
          expect(find.text('SEARCH'), findsOneWidget);
          expect(find.text('NEW'), findsOneWidget);
          expect(find.text('MENU'), findsOneWidget);
          expect(tester.getSize(find.byType(LightConversationRow).first).width,
              360);
          await tester.scrollUntilVisible(find.text('Taylor'), 160);
          await tester.pumpAndSettle();
          expect(find.text('Taylor').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
      'row preserves tap, selection, unread, pin, mute and context actions',
      (tester) async {
    int taps = 0;
    int holds = 0;
    int secondaryTaps = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: createLightPhoneTheme(Brightness.dark),
      home: Scaffold(
        body: LightConversationRow(
          title: const Text('Alex'),
          preview: const Text('Meet at noon.'),
          timestamp: '11:12',
          selected: true,
          unread: true,
          pinned: true,
          muted: true,
          onTap: () => taps++,
          onLongPress: () => holds++,
          onSecondaryTapUp: (_) => secondaryTaps++,
        ),
      ),
    ));
    final row = find.byType(LightConversationRow);
    await tester.tap(row);
    expect(taps, 1);
    await tester.longPress(row);
    expect(holds, 1);
    final gesture = await tester.startGesture(
      tester.getCenter(row),
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pump();
    expect(secondaryTaps, 1);
    expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Pinned')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Muted')), findsOneWidget);
    final selectedNode = tester.getSemantics(row);
    expect(selectedNode.hasFlag(ui.SemanticsFlag.isSelected), isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final height in [413.0, 800.0]) {
    for (final scale in [1.0, 1.6]) {
      for (final brightness in Brightness.values) {
        testWidgets(
            'conversation 360x$height, text $scale, ${brightness.name}: wraps and scrolls',
            (tester) async {
          tester.view.physicalSize = Size(360, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(LightComponentPreview(
            brightness: brightness,
            textScale: scale,
            conversation: true,
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Message'), findsOneWidget);
          expect(find.byTooltip('Record voice note').hitTestable(),
              findsOneWidget);
          await tester.scrollUntilVisible(find.text('Delivered'), 160);
          await tester.pumpAndSettle();
          expect(find.text('Delivered').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        '${brightness.name} messages have no boxes or fill and retain selection contrast',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: createLightPhoneTheme(brightness),
        home: const Scaffold(
            body: Column(children: [
          LightMessageSurface(isFromMe: false, child: Text('Received')),
          LightMessageSurface(isFromMe: true, child: Text('Sent')),
          LightMessageSurface(
              isFromMe: true, selected: true, child: Text('Selected')),
        ])),
      ));
      Color background(String text) {
        final surface = find.ancestor(
            of: find.text(text), matching: find.byType(LightMessageSurface));
        final container = tester.widget<Container>(find
            .descendant(of: surface, matching: find.byType(Container))
            .first);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, isNull);
        expect(decoration.border, isNull);
        return decoration.color!;
      }

      for (final text in ['Received', 'Sent', 'Selected']) {
        final style =
            DefaultTextStyle.of(tester.element(find.text(text))).style;
        expect(style.fontFamily, 'Inter');
        expect(style.fontSize, 14);
        expect(style.height, 1.45);
        final fill = background(text);
        final canvas =
            Theme.of(tester.element(find.text(text))).scaffoldBackgroundColor;
        expect(contrast(style.color!, Color.alphaBlend(fill, canvas)),
            greaterThanOrEqualTo(4.5));
      }
      expect(background('Received'), Colors.transparent);
      expect(background('Sent'), Colors.transparent);
      expect(background('Selected'), isNot(Colors.transparent));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '${brightness.name} sender captions sit above smaller than message text',
        (tester) async {
      tester.view.physicalSize = const Size(360, 413);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
        theme: createLightPhoneTheme(brightness),
        home: const Scaffold(
          body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LightMessageSender(name: 'Jamie'),
            LightMessageSurface(
                isFromMe: false, child: Text('I can bring coffee.')),
            LightMessageSender(name: 'You', isFromMe: true),
            LightMessageSurface(isFromMe: true, child: Text('See you soon.')),
          ]),
        ),
      ));
      final caption = tester.widget<Text>(find.text('Jamie')).style!;
      final body =
          DefaultTextStyle.of(tester.element(find.text('I can bring coffee.')))
              .style;
      expect(caption.fontSize, 11);
      expect(tester.widget<Text>(find.text('You')).style!.fontSize, 11);
      expect(body.fontSize, 14);
      expect(
          tester
              .renderObject<RenderParagraph>(find.text('I can bring coffee.'))
              .textScaler
              .scale(14),
          closeTo(22.4, 0.01));
      expect(
          tester
              .renderObject<RenderParagraph>(find.text('Jamie'))
              .textScaler
              .scale(11),
          closeTo(17.6, 0.01));
      expect(find.bySemanticsLabel('I can bring coffee.'), findsOneWidget);
      expect(find.bySemanticsLabel('See you soon.'), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Jamie')).dy,
          lessThan(tester.getTopLeft(find.text('I can bring coffee.')).dy));
      expect(tester.getBottomLeft(find.text('You')).dy,
          lessThan(tester.getTopLeft(find.text('See you soon.')).dy));
      expect(
          DefaultTextStyle.of(tester.element(find.text('I can bring coffee.')))
              .textAlign,
          TextAlign.left);
      expect(
          DefaultTextStyle.of(tester.element(find.text('See you soon.')))
              .textAlign,
          TextAlign.right);
      expect(
          contrast(
              caption.color!,
              Theme.of(tester.element(find.text('Jamie')))
                  .scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets(
      'compact keyboard viewport keeps send reachable with reply and attachments at 1.6x',
      (tester) async {
    tester.view.physicalSize = const Size(360, 413);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    int sent = 0;
    await tester.pumpWidget(MaterialApp(
      theme: createLightPhoneTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.6)),
        child: child!,
      ),
      home: _ComposerIntegrationFixture(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              height: 100,
              child:
                  Text('Replying to a previous message with several lines.')),
          const SizedBox(
              height: 100, child: Center(child: Text('Attachment preview'))),
          const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'A multiline draft message which stays above the keyboard.')),
          SizedBox(
              height: 48,
              child: TextButton(
                  onPressed: () => sent++, child: const Text('SEND'))),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(LightComposerViewport)).height,
        lessThanOrEqualTo((413 - 200 - kToolbarHeight) * 0.65));
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    await tester.tap(find.text('SEND'));
    expect(sent, 1);
    await tester.scrollUntilVisible(find.text('Attachment preview'), -80);
    await tester.pumpAndSettle();
    expect(find.text('Attachment preview').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tall screen short composer leaves all remaining space to transcript',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: createLightPhoneTheme(Brightness.dark),
      home: const _ComposerIntegrationFixture(
          child: SizedBox(height: 68, child: Center(child: Text('Message')))),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final body =
        tester.getRect(find.byKey(const ValueKey('composer-layout-body')));
    final transcript = tester
        .getRect(find.byKey(const ValueKey('composer-layout-transcript')));
    final composer = tester.getRect(find.byType(LightComposerViewport));
    expect(composer.height, 68);
    expect(transcript.height, body.height - composer.height);
    expect(transcript.bottom, composer.top);
    expect(composer.bottom, body.bottom);
  });

  if (const bool.fromEnvironment('RENDER_PREVIEWS')) {
    for (final height in [413.0, 800.0]) {
      for (final brightness in Brightness.values) {
        for (final conversation in [false, true]) {
          final screen = conversation ? 'conversation' : 'inbox';
          testWidgets(
              'render sample-data $screen ${brightness.name} component preview at 360x$height',
              (tester) async {
            tester.view.physicalSize = Size(360, height);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            await tester.pumpWidget(LightComponentPreview(
                brightness: brightness,
                captureKey: key,
                conversation: conversation));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 3);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  'previews/$screen-${brightness.name}-360x${height.toInt()}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          });
        }
      }
    }
  }
}

/// Mirrors ConversationView's non-flex composer constraint and Stack/Align
/// sizing. The body extends behind the toolbar, so the cap reserves its height.
class _ComposerIntegrationFixture extends StatelessWidget {
  const _ComposerIntegrationFixture({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('Alex')),
        body: LayoutBuilder(
            builder: (context, constraints) => Column(
                  key: const ValueKey('composer-layout-body'),
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Expanded(
                        child: SizedBox.expand(
                            key: ValueKey('composer-layout-transcript'))),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: (constraints.maxHeight - kToolbarHeight)
                                  .clamp(0.0, double.infinity) *
                              0.65),
                      child: Stack(children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: 1,
                          child: LightComposerViewport(child: child),
                        )
                      ]),
                    ),
                  ],
                )),
      );
}
