import 'package:flutter/material.dart';

/// Read-only browser rendering of the Android settings landing page.
///
/// Labels, sections, icons and spacing follow SettingsPage and its settings
/// widgets. This sample represents the Android hosted-device configuration;
/// server-only and desktop-only sections are conditional in the real app.
/// Importing that page here would initialize account, Rust and device services.
class DemoSettingsPage extends StatelessWidget {
  const DemoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // The native settings use the saved Material theme. This isolated preview
    // has no saved account theme, so use the original blue Material defaults.
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
      textTheme: Typography.englishLike2021.merge(
        brightness == Brightness.dark
            ? Typography.whiteMountainView
            : Typography.blackMountainView,
      ),
    );
    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: false,
            toolbarHeight: 50,
            elevation: 0,
            scrolledUnderElevation: 3,
            backgroundColor: colors.surface,
            surfaceTintColor: colors.primary,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            key: const ValueKey('demo-settings-list'),
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              Container(
                color: colors.surfaceContainerHighest,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local preview · Read-only settings',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Original Android settings layout with a sample profile '
                      'and hosted device. Use the Android app to change settings. '
                      'Available sections depend on your account setup.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const _SectionHeader('Profile', initial: true),
              const _SettingsRow(
                'Sample user',
                Icons.person,
                subtitle: 'Sample profile · no account connected',
                profile: true,
              ),
              const _SectionHeader('Device'),
              const _SettingsRow(
                'Hosted Device',
                Icons.laptop,
                subtitle: 'Sample device · details unavailable',
              ),
              const _SettingsRow(
                  'Scheduled Messages', Icons.schedule_send_outlined),
              const _SettingsRow('Message Reminders', Icons.alarm),
              const _SectionHeader('Appearance'),
              const _SettingsRow('Appearance Settings', Icons.palette),
              const _SectionHeader('Application Settings'),
              const _SettingsRow('Media Settings', Icons.attachment),
              const _SettingsRow(
                  'Notification Settings', Icons.notifications_on),
              const _SettingsRow('Chat List Settings', Icons.list),
              const _SettingsRow('Conversation Settings', Icons.sms),
              const _SettingsRow('More Settings', Icons.more_vert),
              const _SectionHeader('Advanced'),
              const _SettingsRow('Redacted Mode', Icons.auto_fix_high),
              const _SettingsRow(
                  'Tasker Integration', Icons.electric_bolt_outlined),
              const _SettingsRow(
                'Developer Tools',
                Icons.adb,
                subtitle: 'View logs, troubleshoot bugs, and more',
              ),
              const _SectionHeader('Backup and Restore'),
              const _SettingsRow(
                'Backup & Restore',
                Icons.backup,
                subtitle:
                    'Backup and restore all app settings and custom themes',
              ),
              const _SectionHeader('About & Links'),
              const _SettingsRow(
                'Leave Us a Review',
                Icons.star,
                subtitle:
                    'Enjoying the app? Leave us a review on the Google Play Store!',
              ),
              const _SettingsRow(
                'Join Our Discord',
                Icons.discord,
                subtitle: 'Join our Discord server to chat with other '
                    'OpenBubbles users and the developers',
              ),
              const _SettingsRow(
                'About & More',
                Icons.info,
                subtitle: 'Links, Changelog, & More',
              ),
              const _SectionHeader('Danger Zone'),
              const _SettingsRow(
                'Delete All Attachments',
                Icons.delete_forever_outlined,
                subtitle: 'Remove all attachments from this app',
              ),
              const _SettingsRow(
                'Reconfigure',
                Icons.settings,
                subtitle: 'Keep messages and reconfigure',
              ),
              const _SettingsRow(
                'Change Apple Hardware',
                Icons.laptop,
                subtitle: 'Keep messages and change hardware',
              ),
              const _SettingsRow(
                'Reset App',
                Icons.refresh_rounded,
                subtitle: 'Resets the app to default settings',
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.initial = false});
  final String text;
  final bool initial;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: initial ? 50 : 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow(this.title, this.icon,
      {this.subtitle, this.profile = false});
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      enabled: false,
      minVerticalPadding: 10,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: profile
            ? CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(icon, color: theme.colorScheme.outline),
              )
            : SizedBox(
                width: 30,
                height: 30,
                child: Icon(icon, size: 28, color: theme.colorScheme.outline),
              ),
      ),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
                height: 1.5,
              ),
            ),
    );
  }
}
