import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_conversation_row.dart';
import '../demo_app.dart';
import '../recipient_picker.dart';

void main() {
  testWidgets(
      'compact inbox shows four full rows without a header and keeps navigation context',
      (tester) async {
    tester.view.physicalSize = const Size(360, 413);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(const LightDemoApp());
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Messages'), findsNothing);
    final label = tester.getRect(find.text('LOCAL DEMO · NO REAL SENDS'));
    expect(label.top, greaterThanOrEqualTo(24));
    for (final action in ['SEARCH', 'NEW', 'MENU']) {
      expect(find.text(action).hitTestable(), findsOneWidget);
    }
    final navigationTop =
        tester.getRect(find.widgetWithText(TextButton, 'SEARCH')).top;
    final rows = find.byType(LightConversationRow);
    expect(rows.evaluate().length, greaterThanOrEqualTo(4));
    for (var index = 0; index < 4; index++) {
      final row = tester.getRect(rows.at(index));
      expect(row.top, greaterThanOrEqualTo(label.bottom));
      expect(row.bottom, lessThanOrEqualTo(navigationTop));
    }

    await tester.tap(find.text('SEARCH'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Search'), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 48);
    expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    await tester.tap(find.text('Alex Morgan'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Alex Morgan'), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 56);
    expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
