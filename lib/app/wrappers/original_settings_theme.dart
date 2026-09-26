import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Keeps the existing Settings pages on the user's original OpenBubbles theme.
/// The Light skin remains selected for conversations and the inbox.
class OriginalSettingsTheme extends StatelessWidget {
  const OriginalSettingsTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);
    final inheritedTheme = Theme.of(context);
    return Obx(() {
      final isLight = ss.settings.skin.value == Skins.Light;
      final original = adaptiveTheme.theme;
      return Theme(
        // Keep the same widget structure when the user changes skins here so
        // Settings state and its existing tablet navigator stay mounted.
        data: isLight
            ? original.copyWith(
                appBarTheme: original.appBarTheme.copyWith(elevation: 0),
                extensions: [
                  ...original.extensions.values,
                  const OriginalSettingsMaterial(),
                ],
              )
            : inheritedTheme,
        child: child,
      );
    });
  }
}

/// A route is a sibling of its source page, so it needs its own theme scope.
/// The inner Builder also gives inline page builders the restored theme.
WidgetBuilder originalSettingsPageBuilder(WidgetBuilder builder) =>
    (context) => OriginalSettingsTheme(child: Builder(builder: builder));
