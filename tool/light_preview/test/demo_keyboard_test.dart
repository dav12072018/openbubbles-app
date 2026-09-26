import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_theme.dart';
import '../demo_keyboard.dart';

Finder keyboardKey(String id) => find.byKey(ValueKey('demo-keyboard-$id'));

Future<void> pumpKeyboard(
  WidgetTester tester, {
  required TextEditingController controller,
  required FocusNode focus,
  VoidCallback? onChanged,
  VoidCallback? onHide,
  double height = DemoKeyboard.defaultHeight,
  double textScale = 1,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = const Size(360, 413);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: createLightPhoneTheme(brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: TextField(
        key: const ValueKey('keyboard-editor'),
        controller: controller,
        focusNode: focus,
        maxLines: 4,
      ),
      bottomNavigationBar: DemoKeyboard(
        controller: controller,
        onChanged: onChanged ?? () {},
        onHide: onHide ?? () {},
        height: height,
      ),
    ),
  ));
  await tester.tap(find.byKey(const ValueKey('keyboard-editor')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('insertion replaces selection, clears composing and keeps focus',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var changed = 0;
    await pumpKeyboard(tester,
        controller: controller, focus: focus, onChanged: () => changed++);
    controller.value = const TextEditingValue(
      text: 'Hello world!',
      selection: TextSelection(baseOffset: 11, extentOffset: 6),
      composing: TextRange(start: 6, end: 11),
    );
    await tester.pump();
    await tester.tap(keyboardKey('key-q'));
    await tester.pump();
    expect(controller.text, 'Hello q!');
    expect(controller.selection, const TextSelection.collapsed(offset: 7));
    expect(controller.value.composing, TextRange.empty);
    expect(changed, 1);
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backspace deletes whole emoji, flags and combining characters',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await pumpKeyboard(tester, controller: controller, focus: focus);
    const prefix = 'go 👩‍👩‍👧‍👦🇮🇹e\u0301';
    controller.value = const TextEditingValue(
      text: '$prefix!',
      selection: TextSelection.collapsed(offset: prefix.length),
    );
    for (final expected in ['go 👩‍👩‍👧‍👦🇮🇹!', 'go 👩‍👩‍👧‍👦!', 'go !']) {
      await tester.tap(keyboardKey('backspace'));
      await tester.pump();
      expect(controller.text, expected);
      expect(controller.selection.extentOffset, expected.length - 1);
    }
    // A programmatically placed cursor inside a complex emoji is safe too.
    controller.value = const TextEditingValue(
      text: 'X🧑🏽‍💻Y',
      selection: TextSelection.collapsed(offset: 3),
    );
    await tester.tap(keyboardKey('backspace'));
    await tester.pump();
    expect(controller.text, 'XY');
    expect(controller.selection, const TextSelection.collapsed(offset: 1));
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backspace removes selection and does nothing at the beginning',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var changed = 0;
    await pumpKeyboard(tester,
        controller: controller, focus: focus, onChanged: () => changed++);
    controller.value = const TextEditingValue(
        text: 'keep delete done',
        selection: TextSelection(baseOffset: 11, extentOffset: 5));
    await tester.tap(keyboardKey('backspace'));
    await tester.pump();
    expect(controller.text, 'keep  done');
    expect(controller.selection, const TextSelection.collapsed(offset: 5));
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.tap(keyboardKey('backspace'));
    expect(controller.text, 'keep  done');
    expect(changed, 1);
  });

  testWidgets('shift, space, newline and symbol modes edit at the caret',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await pumpKeyboard(tester, controller: controller, focus: focus);
    await tester.tap(keyboardKey('shift'));
    await tester.pump();
    await tester.tap(keyboardKey('key-H'));
    await tester.pump();
    expect(keyboardKey('key-h'), findsOneWidget);
    await tester.tap(keyboardKey('key-i'));
    await tester.tap(keyboardKey('space'));
    await tester.tap(keyboardKey('return'));
    await tester.tap(keyboardKey('symbols'));
    await tester.pump();
    await tester.tap(keyboardKey('key-7'));
    await tester.tap(keyboardKey('key-?'));
    await tester.tap(keyboardKey('shift'));
    await tester.pump();
    await tester.tap(keyboardKey('key-#'));
    await tester.tap(keyboardKey('symbols'));
    await tester.pump();
    await tester.tap(keyboardKey('key-a'));
    await tester.pump();
    expect(controller.text, 'Hi \n7?#a');
    expect(controller.selection,
        TextSelection.collapsed(offset: controller.text.length));
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final height in [172.0, 140.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('360px/$height keyboard fits at 1.6x in ${brightness.name}',
          (tester) async {
        final controller = TextEditingController();
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        var hidden = 0;
        await pumpKeyboard(tester,
            controller: controller,
            focus: focus,
            height: height,
            textScale: 1.6,
            brightness: brightness,
            onHide: () => hidden++);
        final rect = tester.getRect(find.byType(DemoKeyboard));
        expect(rect.width, 360);
        expect(rect.height, height);
        for (final button in find
            .descendant(
                of: find.byType(DemoKeyboard),
                matching: find.byType(TextButton))
            .evaluate()) {
          final bounds = tester.getRect(find.byWidget(button.widget));
          expect(bounds.left, greaterThanOrEqualTo(rect.left));
          expect(bounds.right, lessThanOrEqualTo(rect.right));
          expect(bounds.top, greaterThanOrEqualTo(rect.top));
          expect(bounds.bottom, lessThanOrEqualTo(rect.bottom));
        }
        await tester.tap(keyboardKey('symbols'));
        await tester.pump();
        await tester.tap(keyboardKey('shift'));
        await tester.pump();
        await tester.tap(keyboardKey('key-€'));
        await tester.pump();
        expect(controller.text, '€');
        await tester.tap(find.byTooltip('Hide keyboard'));
        expect(hidden, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
