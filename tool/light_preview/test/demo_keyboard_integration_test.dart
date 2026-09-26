import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../demo_app.dart';
import '../demo_keyboard.dart';

final draftField = find.byKey(const ValueKey('demo-draft'));
final previewKeyboard = find.byType(DemoKeyboard);

Future<void> openKeyboardDemo(WidgetTester tester,
    {Size size = const Size(360, 800), double textScale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(const LightDemoApp(simulateKeyboard: true));
  await tester.tap(find.text('Alex Morgan'));
  await tester.pumpAndSettle();
  expect(previewKeyboard, findsNothing);
  await tester.tap(draftField, kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
  expect(previewKeyboard, findsOneWidget);
}

Future<void> typeWithKeyboard(WidgetTester tester, String text) async {
  for (final character in text.split('')) {
    final key = character == ' '
        ? 'demo-keyboard-space'
        : 'demo-keyboard-key-$character';
    await tester.tap(find.byKey(ValueKey(key)), kind: PointerDeviceKind.mouse);
    await tester.pump();
    expect(tester.widget<TextField>(draftField).focusNode!.hasFocus, isTrue);
    expect(previewKeyboard, findsOneWidget);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'composer tap opens preview keyboard and key taps type without losing focus',
      (tester) async {
    await openKeyboardDemo(tester);
    await typeWithKeyboard(tester, 'hi there');
    expect(tester.widget<TextField>(draftField).controller!.text, 'hi there');
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('SEND')).bottom,
        lessThanOrEqualTo(tester.getRect(previewKeyboard).top + 0.01));
    await tester.tap(find.text('SEND'), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(find.text('hi there'), findsOneWidget);
    expect(tester.getRect(find.text('hi there')).right, closeTo(342, 0.01));
    expect(tester.widget<TextField>(draftField).controller!.text, isEmpty);
    expect(previewKeyboard, findsOneWidget);
    expect(tester.widget<TextField>(draftField).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hide, reopen and Escape preserve the editable draft',
      (tester) async {
    await openKeyboardDemo(tester);
    await typeWithKeyboard(tester, 'hello');
    await tester.tap(find.byKey(const ValueKey('demo-keyboard-hide')));
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsNothing);
    expect(tester.widget<TextField>(draftField).controller!.text, 'hello');
    await tester.tap(draftField);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('demo-keyboard-backspace')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(draftField).controller!.text, 'hell');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsNothing);
    expect(tester.widget<TextField>(draftField).controller!.text, 'hell');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'leaving the conversation closes the keyboard until another composer is focused',
      (tester) async {
    await openKeyboardDemo(tester);
    await typeWithKeyboard(tester, 'draft');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsNothing);
    expect(find.text('NEW').hitTestable(), findsOneWidget);
    expect(find.text('Sam Rivera').hitTestable(), findsOneWidget);
    expect(previewKeyboard, findsNothing);
    await tester.tap(find.text('Sam Rivera'));
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsNothing);
    expect(tester.widget<TextField>(draftField).controller!.text, isEmpty);
    await tester.tap(draftField);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'compact 360x413 at 1.6x keeps keys and SEND reachable above the keyboard',
      (tester) async {
    await openKeyboardDemo(tester, size: const Size(360, 413), textScale: 1.6);
    await typeWithKeyboard(tester, 'hi');
    final keyboardRect = tester.getRect(previewKeyboard);
    expect(keyboardRect.left, closeTo(0, 0.01));
    expect(keyboardRect.right, closeTo(360, 0.01));
    expect(keyboardRect.bottom, lessThanOrEqualTo(413.01));
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('SEND')).bottom,
        lessThanOrEqualTo(keyboardRect.top + 0.01));
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
    expect(tester.widget<TextField>(draftField).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a real keyboard inset suppresses the simulated keyboard without discarding text',
      (tester) async {
    await openKeyboardDemo(tester, size: const Size(360, 413));
    await typeWithKeyboard(tester, 'hello');
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsNothing);
    expect(tester.widget<TextField>(draftField).controller!.text, 'hello');
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('SEND')).bottom, lessThanOrEqualTo(213.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'desktop keyboard remains inside the 360px phone frame despite the wider MediaQuery',
      (tester) async {
    tester.view.physicalSize = const Size(640, 664);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
          child: SizedBox(
        key: ValueKey('keyboard-phone-frame'),
        width: 360,
        height: 413,
        child: ClipRect(child: LightDemoApp(simulateKeyboard: true)),
      )),
    ));
    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    await tester.tap(draftField);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsOneWidget);
    expect(MediaQuery.sizeOf(tester.element(previewKeyboard)).width, 640);
    final frame =
        tester.getRect(find.byKey(const ValueKey('keyboard-phone-frame')));
    final keyboardRect = tester.getRect(previewKeyboard);
    expect(keyboardRect.width, closeTo(360, 0.01));
    expect(keyboardRect.left, closeTo(frame.left, 0.01));
    expect(keyboardRect.right, closeTo(frame.right, 0.01));
    expect(keyboardRect.bottom, lessThanOrEqualTo(frame.bottom + 0.01));
    await typeWithKeyboard(tester, 'hi');
    expect(find.text('SEND').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.text('SEND')).bottom,
        lessThanOrEqualTo(keyboardRect.top + 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'disabling the simulator retains a normal system-keyboard text field',
      (tester) async {
    await tester.pumpWidget(const LightDemoApp(simulateKeyboard: false));
    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    await tester.tap(draftField);
    await tester.pumpAndSettle();
    expect(previewKeyboard, findsNothing);
    expect(tester.widget<TextField>(draftField).readOnly, isFalse);
    await tester.enterText(draftField, 'System keyboard input');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(draftField).controller!.text,
        'System keyboard input');
    expect(tester.takeException(), isNull);
  });
}
