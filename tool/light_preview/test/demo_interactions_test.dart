import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../demo_app.dart';
import '../recipient_picker.dart';

void main() {
  testWidgets('open, write locally, return and search sample conversations',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const LightDemoApp());
    expect(find.text('LOCAL DEMO · NO REAL SENDS'), findsOneWidget);
    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('demo-draft')), 'Testing this locally.');
    await tester.pump();
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.text('Testing this locally.'), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('demo-draft')))
            .controller!
            .text,
        isEmpty);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('You: Testing this locally.'), findsOneWidget);
    await tester.tap(find.text('SEARCH'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('demo-search')), 'Taylor');
    await tester.pumpAndSettle();
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == 'Taylor'),
        findsOneWidget);
    expect(find.text('Alex Morgan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new thread, theme switch, reset and menu back work',
      (tester) async {
    tester.view.physicalSize = const Size(360, 413);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const LightDemoApp());
    await tester.tap(find.text('NEW'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('demo-recipient-query')), 'Casey');
    await tester.pumpAndSettle();
    final casey =
        demoContacts.firstWhere((contact) => contact.name == 'Casey Park');
    await tester
        .tap(find.byKey(ValueKey('recipient-suggestion-${casey.address}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-recipient-next')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Casey Park'), findsOneWidget);
    expect(find.text('Write a message to try it.'), findsOneWidget);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use light appearance'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to demo'));
    await tester.pumpAndSettle();
    expect(find.text('Casey Park'), findsOneWidget);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset sample conversations'));
    await tester.pumpAndSettle();
    expect(find.text('Casey Park'), findsNothing);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
