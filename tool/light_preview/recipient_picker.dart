import 'package:flutter/material.dart';

/// Fictional contacts used only by the local demo.
class DemoRecipient {
  const DemoRecipient({required this.name, required this.address});

  final String name;
  final String address;

  String get identity {
    if (address.contains('@')) return address.toLowerCase();
    final digits = address.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('1')
        ? digits.substring(1)
        : digits;
  }
}

const demoContacts = [
  DemoRecipient(name: 'Alex Morgan', address: '+1 (202) 555-0101'),
  DemoRecipient(name: 'Alex Morgan', address: 'alex.morgan@example.com'),
  DemoRecipient(name: 'Sam Rivera', address: 'sam.rivera@example.com'),
  DemoRecipient(name: 'Jamie Lee', address: '+1 (202) 555-0102'),
  DemoRecipient(name: 'Morgan Chen', address: 'morgan.chen@example.com'),
  DemoRecipient(name: 'Casey Park', address: 'casey.park@example.com'),
  DemoRecipient(name: 'Taylor', address: '+1 (202) 555-0103'),
];

/// Recipient selection precedes the message composer, as in the Android app.
class DemoRecipientPicker extends StatefulWidget {
  const DemoRecipientPicker({super.key});

  @override
  State<DemoRecipientPicker> createState() => _DemoRecipientPickerState();
}

class _DemoRecipientPickerState extends State<DemoRecipientPicker> {
  final query = TextEditingController();
  final queryFocus = FocusNode();
  final selected = <DemoRecipient>[];
  String? error;

  @override
  void dispose() {
    query.dispose();
    queryFocus.dispose();
    super.dispose();
  }

  bool contains(DemoRecipient recipient) =>
      selected.any((item) => item.identity == recipient.identity);

  List<DemoRecipient> get suggestions {
    final text = query.text.trim().toLowerCase();
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final phoneQuery =
        digits.isNotEmpty && RegExp(r'^[+\d().\s-]+$').hasMatch(text);
    return demoContacts.where((item) {
      return !contains(item) &&
          (item.name.toLowerCase().contains(text) ||
              item.address.toLowerCase().contains(text) ||
              (phoneQuery &&
                  !item.address.contains('@') &&
                  item.address.replaceAll(RegExp(r'\D'), '').contains(digits)));
    }).toList();
  }

  DemoRecipient? get typedRecipient {
    final text = query.text.trim();
    final email = RegExp(r'^[^\s@,;]+@[^\s@,;]+\.[^\s@,;]+$').hasMatch(text);
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final phone = RegExp(r'^\+?[\d().\s-]+$').hasMatch(text) &&
        digits.length >= 7 &&
        digits.length <= 15;
    if (!email && !phone) return null;
    final recipient = DemoRecipient(name: text, address: text);
    return demoContacts.firstWhere(
        (item) => item.identity == recipient.identity,
        orElse: () => recipient);
  }

  void add(DemoRecipient recipient) {
    setState(() {
      if (!contains(recipient)) selected.add(recipient);
      query.clear();
      error = null;
    });
    queryFocus.requestFocus();
  }

  void submitQuery() {
    final recipient = typedRecipient;
    final matches = suggestions;
    if (recipient != null) {
      add(recipient);
    } else if (query.text.trim().isNotEmpty && matches.isNotEmpty) {
      add(matches.first);
    } else if (query.text.trim().isNotEmpty) {
      setState(
          () => error = 'Choose a contact, or enter a phone number or email.');
    }
  }

  void next() {
    final recipient = typedRecipient;
    if (recipient != null && !contains(recipient)) selected.add(recipient);
    if (selected.isEmpty || (query.text.trim().isNotEmpty && recipient == null))
      return;
    FocusScope.of(context).unfocus();
    Navigator.pop(context, List<DemoRecipient>.unmodifiable(selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = suggestions;
    final typed = typedRecipient;
    final canContinue = (selected.isNotEmpty || typed != null) &&
        (query.text.trim().isEmpty || typed != null);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          tooltip: 'Cancel new conversation',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('New message',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            key: const ValueKey('demo-recipient-next'),
            onPressed: canContinue ? next : null,
            child: const Text('NEXT'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            for (final recipient in selected)
              Row(
                key: ValueKey('selected-recipient-${recipient.address}'),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipient.name),
                        if (recipient.name != recipient.address)
                          Text(recipient.address,
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('remove-recipient-${recipient.address}'),
                    tooltip: 'Remove ${recipient.name}',
                    onPressed: () => setState(() => selected.remove(recipient)),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            TextField(
              key: const ValueKey('demo-recipient-query'),
              controller: query,
              focusNode: queryFocus,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => error = null),
              onSubmitted: (_) => submitQuery(),
              decoration: InputDecoration(
                labelText: selected.isEmpty ? 'To' : 'Add recipient',
                hintText: 'Name, phone or email',
                errorText: error,
                errorMaxLines: 3,
                suffixIcon: typed == null
                    ? null
                    : IconButton(
                        tooltip: 'Add recipient',
                        onPressed: () => add(typed),
                        icon: const Icon(Icons.add),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(query.text.trim().isEmpty ? 'Sample contacts' : 'Suggestions',
                style: theme.textTheme.bodySmall),
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  typed != null
                      ? 'Use + to add this recipient, or NEXT to write your message.'
                      : 'No matching contacts. Enter a phone number or email.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            for (final recipient in matches)
              Semantics(
                button: true,
                child: ListTile(
                  key: ValueKey('recipient-suggestion-${recipient.address}'),
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 12,
                  title: Text(recipient.name),
                  subtitle:
                      Text(recipient.address, style: theme.textTheme.bodySmall),
                  onTap: () => add(recipient),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
