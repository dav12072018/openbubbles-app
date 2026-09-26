import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_message_sender.dart';
import '../demo_app.dart';
import '../images/image_factory.dart';

// A valid, lossless 4×2 PNG created for this test, without user files.
final imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAYAAAB/qH1jAAAADklEQVR4nGP4jwYY0AUAHiAf4RadhQcAAAAASUVORK5CYII=');

class FakeImagePicker implements LocalImagePicker {
  List<LocalImage> next = [];
  Completer<List<LocalImage>>? pending;
  int calls = 0;

  @override
  Future<List<LocalImage>> pick() async {
    calls++;
    return pending == null ? next : await pending!.future;
  }

  @override
  void dispose() {}
}

Future<void> openImagesDemo(WidgetTester tester, FakeImagePicker picker,
    {String thread = 'Alex Morgan', bool compact = false}) async {
  tester.view.physicalSize = Size(360, compact ? 413 : 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(LightDemoApp(imagePicker: picker));
  if (thread == 'Image preview') {
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/images/sample-image.png'),
        tester.element(find.byType(Scaffold).first)));
  }
  await tester.tap(find.text(thread));
  await tester.pumpAndSettle();
}

Future<void> chooseImages(WidgetTester tester, FakeImagePicker picker,
    List<LocalImage> images) async {
  picker.next = images;
  await tester.runAsync(() async {
    await tester.tap(find.byTooltip('Add images'));
    // Decode uses the real engine rather than the test's fake clock.
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  await tester.pumpAndSettle();
}

Finder draftImage(String name) => find.byKey(ValueKey('draft-image-$name'));
Finder messageImage(String name) => find.byKey(ValueKey('message-image-$name'));

void main() {
  testWidgets(
      'desktop frame sizes thumbnails from the phone bounds before image decoding',
      (tester) async {
    tester.view.physicalSize = const Size(640, 664);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
          child: SizedBox(
        key: const ValueKey('phone-frame'),
        width: 360,
        height: 413,
        child: ClipRect(child: LightDemoApp(imagePicker: FakeImagePicker())),
      )),
    ));
    await tester.tap(find.text('Image preview'));
    await tester.pump();
    final frame = tester.getRect(find.byKey(const ValueKey('phone-frame')));
    final incoming = messageImage('received-sample.png');
    final outgoing = messageImage('sent-sample.png');
    expect(MediaQuery.sizeOf(tester.element(incoming)).width, 640);

    void expectPhoneSizedImages() {
      for (final image in [incoming, outgoing]) {
        final size = tester.getSize(image);
        expect(size.width, closeTo(180, 0.01));
        expect(size.height, closeTo(112.5, 0.01));
      }
      expect(tester.getRect(incoming).left, closeTo(frame.left + 18, 0.01));
      expect(tester.getRect(outgoing).right, closeTo(frame.right - 18, 0.01));
    }

    expectPhoneSizedImages();
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/images/sample-image.png'),
        tester.element(incoming)));
    await tester.pumpAndSettle();
    expectPhoneSizedImages();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sample incoming and sent images preserve fit, direction and fullscreen viewing',
      (tester) async {
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker, thread: 'Image preview');
    expect(picker.calls, 0);
    final incoming = messageImage('received-sample.png');
    final outgoing = messageImage('sent-sample.png');
    expect(tester.getRect(incoming).left, closeTo(18, 0.01));
    expect(tester.getRect(outgoing).right, closeTo(342, 0.01));
    for (final image in [incoming, outgoing]) {
      final rendered = tester.widget<Image>(
          find.descendant(of: image, matching: find.byType(Image)).first);
      expect(rendered.fit, BoxFit.contain);
    }
    expect(find.byType(LightMessageSender), findsNothing);
    await tester
        .ensureVisible(find.byTooltip('Open image received-sample.png'));
    await tester.tap(find.byTooltip('Open image received-sample.png'));
    await tester.pumpAndSettle();
    expect(find.text('received-sample.png'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    final viewer =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(1));
    await tester.tap(find.byTooltip('Reset zoom'));
    await tester.pumpAndSettle();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1, 0.01));
    await tester.tap(find.byTooltip('Close image'));
    await tester.pumpAndSettle();
    expect(find.text('Image preview'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'picker cancellation and removing every draft image cannot send an empty message',
      (tester) async {
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker);
    expect(picker.calls, 0);
    await chooseImages(tester, picker, []);
    expect(picker.calls, 1);
    expect(find.text('SEND'), findsNothing);
    await chooseImages(tester, picker, [
      LocalImage(bytes: imageBytes, name: 'first.png'),
      LocalImage(bytes: imageBytes, name: 'second.png'),
    ]);
    expect(draftImage('first.png'), findsOneWidget);
    expect(draftImage('second.png'), findsOneWidget);
    expect(find.text('SEND'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove first.png'));
    await tester.pumpAndSettle();
    expect(draftImage('first.png'), findsNothing);
    expect(draftImage('second.png'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove second.png'));
    await tester.pumpAndSettle();
    expect(find.text('SEND'), findsNothing);
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    expect(messageImage('first.png'), findsNothing);
    expect(messageImage('second.png'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'image-only send aligns right and opens the original image for zooming',
      (tester) async {
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker);
    await chooseImages(
        tester, picker, [LocalImage(bytes: imageBytes, name: 'local.png')]);
    final preview = tester.widget<Image>(find
        .descendant(of: draftImage('local.png'), matching: find.byType(Image))
        .first);
    expect(preview.fit, BoxFit.contain);
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(draftImage('local.png'), findsNothing);
    expect(messageImage('local.png'), findsOneWidget);
    expect(tester.getRect(messageImage('local.png')).right, closeTo(342, 0.01));
    expect(find.byType(LightMessageSender), findsNothing);
    await tester.tap(find.byTooltip('Open image local.png'));
    await tester.pumpAndSettle();
    expect(find.text('local.png'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final image = tester.widget<Image>(find
        .descendant(
            of: find.byType(InteractiveViewer), matching: find.byType(Image))
        .first);
    expect(image.fit, BoxFit.contain);
    await tester.tap(find.byTooltip('Close image'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Record voice note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'text and image send together; reset discards the local attachment',
      (tester) async {
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker);
    await chooseImages(
        tester, picker, [LocalImage(bytes: imageBytes, name: 'captioned.png')]);
    await tester.enterText(
        find.byKey(const ValueKey('demo-draft')), 'Here is the photo.');
    await tester.pump();
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.text('Here is the photo.'), findsOneWidget);
    expect(messageImage('captioned.png'), findsOneWidget);
    expect(tester.getRect(find.text('Here is the photo.')).right,
        closeTo(342, 0.01));
    expect(tester.getRect(messageImage('captioned.png')).right,
        closeTo(342, 0.01));
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('demo-draft')))
            .controller!
            .text,
        isEmpty);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset sample conversations'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    expect(messageImage('captioned.png'), findsNothing);
    expect(find.text('Here is the photo.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'invalid image bytes recover without SEND and preserve an existing valid draft',
      (tester) async {
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker);
    final broken =
        LocalImage(bytes: Uint8List.fromList([0, 1, 2, 3]), name: 'broken.png');
    await chooseImages(tester, picker, [broken]);
    expect(find.textContaining('Could not open broken.png.'), findsOneWidget);
    expect(draftImage('broken.png'), findsNothing);
    expect(find.text('SEND'), findsNothing);
    await chooseImages(
        tester, picker, [LocalImage(bytes: imageBytes, name: 'valid.png')]);
    expect(draftImage('valid.png'), findsOneWidget);
    await chooseImages(tester, picker, [broken]);
    expect(draftImage('valid.png'), findsOneWidget);
    expect(draftImage('broken.png'), findsNothing);
    expect(find.text('SEND'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'image send remains reachable at 360x413, 1.6x text and a 200px keyboard',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final picker = FakeImagePicker();
    await openImagesDemo(tester, picker, compact: true);
    await chooseImages(
        tester, picker, [LocalImage(bytes: imageBytes, name: 'compact.png')]);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('SEND')).bottom, lessThanOrEqualTo(213.01));
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(messageImage('compact.png'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending picker cannot leak images into another conversation',
      (tester) async {
    final picker = FakeImagePicker()..pending = Completer<List<LocalImage>>();
    await openImagesDemo(tester, picker);
    await tester.tap(find.byTooltip('Add images'));
    await tester.pumpAndSettle();
    expect(picker.calls, 1);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sam Rivera'));
    await tester.pumpAndSettle();
    final addButton = find.ancestor(
        of: find.byTooltip('Add images'), matching: find.byType(IconButton));
    expect(tester.widget<IconButton>(addButton).onPressed, isNull);
    await tester.tap(find.byTooltip('Add images'));
    expect(picker.calls, 1);
    picker.pending!
        .complete([LocalImage(bytes: imageBytes, name: 'old-thread.png')]);
    await tester.pumpAndSettle();
    expect(draftImage('old-thread.png'), findsNothing);
    expect(messageImage('old-thread.png'), findsNothing);
    expect(tester.widget<IconButton>(addButton).onPressed, isNotNull);
    picker.pending = null;
    await chooseImages(tester, picker,
        [LocalImage(bytes: imageBytes, name: 'new-thread.png')]);
    expect(picker.calls, 2);
    expect(draftImage('new-thread.png'), findsOneWidget);
    expect(draftImage('old-thread.png'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
