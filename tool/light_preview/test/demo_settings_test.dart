import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/components/light/light_theme.dart';
import '../demo_settings.dart';

void main() {
  testWidgets('settings preview stays read-only and scrolls at compact scale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 413);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: createLightPhoneTheme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.6),
        ),
        child: child!,
      ),
      home: const DemoSettingsPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Local preview · Read-only settings'), findsOneWidget);
    final settingsTheme = Theme.of(tester.element(find.text('Settings')));
    expect(settingsTheme.colorScheme.primary,
        isNot(createLightPhoneTheme(Brightness.dark).colorScheme.primary));
    expect(settingsTheme.textTheme.bodyLarge!.fontFamily, isNot('Inter'));

    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('demo-settings-list')),
      matching: find.byType(Scrollable),
    );
    for (final label in [
      'Sample user',
      'Hosted Device',
      'Appearance Settings',
      'Conversation Settings',
      'Developer Tools',
      'Backup & Restore',
      'About & More',
      'Reset App',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 120,
          scrollable: scrollable);
      final row = tester.widget<ListTile>(find.ancestor(
        of: find.text(label),
        matching: find.byType(ListTile),
      ));
      expect(row.enabled, isFalse);
      expect(row.onTap, isNull);
      expect(row.onLongPress, isNull);
      expect(tester.takeException(), isNull);
    }
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
