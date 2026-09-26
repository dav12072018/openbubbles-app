import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../demo_app.dart';
import '../recipient_picker.dart';

final recipientQuery = find.byKey(const ValueKey('demo-recipient-query'));
final recipientNext = find.byKey(const ValueKey('demo-recipient-next'));

Finder suggestion(DemoRecipient contact) =>
    find.byKey(ValueKey('recipient-suggestion-${contact.address}'));
Finder selected(DemoRecipient contact) =>
    find.byKey(ValueKey('selected-recipient-${contact.address}'));

Future<void> openPicker(WidgetTester tester, {bool compact = false}) async {
  tester.view.physicalSize = Size(360, compact ? 413 : 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const LightDemoApp());
  await tester.tap(find.text('NEW'));
  await tester.pumpAndSettle();
  expect(find.text('New message'), findsOneWidget);
}

Future<void> query(WidgetTester tester, String text) async {
  await tester.enterText(recipientQuery, text);
  await tester.pumpAndSettle();
}

Future<void> addContact(WidgetTester tester, DemoRecipient contact) async {
  await query(tester, contact.address);
  await tester.tap(suggestion(contact));
  await tester.pumpAndSettle();
  expect(selected(contact), findsOneWidget);
  expect(tester.widget<TextField>(recipientQuery).controller!.text, isEmpty);
}

void main() {
  final alexPhone = demoContacts.firstWhere((contact) =>
      contact.name == 'Alex Morgan' && !contact.address.contains('@'));
  final alexEmail = demoContacts.firstWhere((contact) =>
      contact.name == 'Alex Morgan' && contact.address.contains('@'));
  final sam =
      demoContacts.firstWhere((contact) => contact.name == 'Sam Rivera');
  final casey =
      demoContacts.firstWhere((contact) => contact.name == 'Casey Park');

  testWidgets('autocomplete searches names, emails and normalized phone digits',
      (tester) async {
    await openPicker(tester);
    await query(tester, 'aLeX');
    expect(suggestion(alexPhone), findsOneWidget);
    expect(suggestion(alexEmail), findsOneWidget);
    expect(suggestion(sam), findsNothing);
    await query(tester, alexPhone.address.replaceAll(RegExp(r'\D'), ''));
    expect(suggestion(alexPhone), findsOneWidget);
    expect(suggestion(alexEmail), findsNothing);
    await query(tester, alexEmail.address.toUpperCase());
    expect(suggestion(alexEmail), findsOneWidget);
    expect(suggestion(alexPhone), findsNothing);
    await query(tester, '');
    expect(suggestion(alexPhone), findsOneWidget);
    expect(suggestion(sam), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'multi-select keeps recipients, removes one and starts group thread',
      (tester) async {
    await openPicker(tester);
    await addContact(tester, alexEmail);
    await addContact(tester, sam);
    await addContact(tester, casey);
    await tester.tap(find.byKey(ValueKey('remove-recipient-${sam.address}')));
    await tester.pumpAndSettle();
    expect(selected(sam), findsNothing);
    expect(selected(alexEmail), findsOneWidget);
    expect(selected(casey), findsOneWidget);
    await tester.tap(recipientNext);
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan, Casey Park'), findsOneWidget);
    expect(find.text('Write a message to try it.'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('demo-draft')), 'Hello both.');
    await tester.pump();
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();
    expect(find.text('Hello both.'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'canonical email and phone duplicates cannot add repeated recipients',
      (tester) async {
    await openPicker(tester);
    await addContact(tester, alexEmail);
    await query(tester, alexEmail.address.toUpperCase());
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(selected(alexEmail), findsOneWidget);
    await addContact(tester, alexPhone);
    await query(tester, alexPhone.address.replaceAll(RegExp(r'\D'), ''));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(selected(alexPhone), findsOneWidget);
    final selectedRows = find.byWidgetPredicate((widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>)
            .value
            .startsWith('selected-recipient-'));
    expect(selectedRows, findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('raw email submits and NEXT includes a valid pending phone',
      (tester) async {
    await openPicker(tester);
    const email = 'friend@example.org';
    const phone = '+44 7700 900123';
    await query(tester, email);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('selected-recipient-$email')),
        findsOneWidget);
    await query(tester, phone);
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNotNull);
    await tester.tap(recipientNext);
    await tester.pumpAndSettle();
    expect(find.text('$email, $phone'), findsOneWidget);
    expect(find.text('Write a message to try it.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'empty and unmatched names cannot create a conversation; cancel discards selection',
      (tester) async {
    await openPicker(tester);
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNull);
    await tester.tap(recipientNext);
    await tester.pumpAndSettle();
    expect(find.text('New message'), findsOneWidget);
    await query(tester, 'No Such Sample Person');
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNull);
    await addContact(tester, casey);
    await query(tester, 'No Such Sample Person');
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNull);
    await tester.tap(find.byTooltip('Cancel new conversation'));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsNothing);
    expect(find.text('SEARCH').hitTestable(), findsOneWidget);
    expect(find.text('Alex Morgan').hitTestable(), findsOneWidget);
    expect(find.text('Casey Park'), findsNothing);
    await tester.tap(find.text('NEW'));
    await tester.pumpAndSettle();
    expect(selected(casey), findsNothing);
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitting a matching name chooses its first suggestion',
      (tester) async {
    await openPicker(tester);
    await query(tester, 'Casey');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(selected(casey), findsOneWidget);
    expect(tester.widget<TextField>(recipientQuery).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NEXT stays reachable on 360x413 with keyboard and 1.6x text',
      (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openPicker(tester, compact: true);
    await addContact(tester, casey);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await query(tester, 'second@example.org');
    expect(tester.widget<TextButton>(recipientNext).onPressed, isNotNull);
    final nextRect = tester.getRect(recipientNext);
    expect(nextRect.top, greaterThanOrEqualTo(0));
    expect(nextRect.bottom, lessThanOrEqualTo(213));
    await tester.tap(recipientNext);
    await tester.pumpAndSettle();
    expect(find.text('Casey Park, second@example.org'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
