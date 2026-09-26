import 'package:flutter/material.dart';

/// An editable keyboard for the desktop demo; mobile uses its system keyboard.
class DemoKeyboard extends StatefulWidget {
  const DemoKeyboard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onHide,
    this.height = defaultHeight,
  });

  static const double defaultHeight = 172;

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onHide;
  final double height;

  @override
  State<DemoKeyboard> createState() => _DemoKeyboardState();
}

class _DemoKeyboardState extends State<DemoKeyboard> {
  bool uppercase = false;
  bool symbols = false;
  bool alternateSymbols = false;

  TextSelection get selection {
    final value = widget.controller.value;
    final selected = value.selection;
    if (!selected.isValid || selected.end > value.text.length) {
      return TextSelection.collapsed(offset: value.text.length);
    }
    return selected;
  }

  void replace(int start, int end, String inserted) {
    final value = widget.controller.value;
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(start, end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length),
      composing: TextRange.empty,
    );
    widget.onChanged();
  }

  void insert(String text) {
    final selected = selection;
    replace(selected.start, selected.end, text);
    if (uppercase && !symbols && text.trim().isNotEmpty) {
      setState(() => uppercase = false);
    }
  }

  void backspace() {
    final selected = selection;
    if (!selected.isCollapsed) {
      replace(selected.start, selected.end, '');
      return;
    }
    if (selected.start == 0) return;
    // Work in grapheme clusters, including ZWJ emoji and regional-indicator
    // flags. Even a cursor placed inside a cluster cannot leave a broken emoji.
    var start = 0;
    for (final character in widget.controller.text.characters) {
      final end = start + character.length;
      if (selected.start <= end) {
        replace(start, end, '');
        return;
      }
      start = end;
    }
  }

  Widget keyButton({
    required String id,
    required String label,
    required VoidCallback onPressed,
    String? tooltip,
    IconData? icon,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final foreground =
        selected ? theme.scaffoldBackgroundColor : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Tooltip(
        message: tooltip ?? label,
        excludeFromSemantics: true,
        child: TextButton(
          key: ValueKey('demo-keyboard-$id'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: foreground,
            backgroundColor: selected
                ? theme.colorScheme.onSurface
                : theme.scaffoldBackgroundColor,
            side:
                BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
            shape: const RoundedRectangleBorder(),
          ),
          child: SizedBox.expand(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: icon == null
                      ? Text(label,
                          semanticsLabel: tooltip ?? label,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w400))
                      : Icon(icon, size: 18, semanticLabel: label),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget characterKey(String character) => Expanded(
        child: keyButton(
          id: 'key-$character',
          label: character,
          onPressed: () => insert(character),
        ),
      );

  List<String> letters(String row) =>
      (uppercase ? row.toUpperCase() : row).split('');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = !symbols
        ? letters('qwertyuiop')
        : alternateSymbols
            ? ['[', ']', '{', '}', '#', '%', '^', '*', '+', '=']
            : '1234567890'.split('');
    final second = !symbols
        ? letters('asdfghjkl')
        : alternateSymbols
            ? ['_', '\\', '|', '~', '<', '>', '€', '£', '¥']
            : ['-', '/', ':', ';', '(', ')', r'$', '&', '@'];
    final third =
        !symbols ? letters('zxcvbnm') : ['.', ',', '?', '!', "'", '"', '_'];
    return TextFieldTapRegion(
      child: Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                  top: BorderSide(
                      color: theme.colorScheme.onSurface, width: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  SizedBox(
                    height: 24,
                    child: Row(children: [
                      Expanded(
                        child: Text('PREVIEW KEYBOARD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall!
                                .copyWith(fontSize: 10, height: 1)),
                      ),
                      Tooltip(
                        message: 'Hide keyboard',
                        excludeFromSemantics: true,
                        child: TextButton(
                          key: const ValueKey('demo-keyboard-hide'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            fixedSize: const Size(48, 24),
                          ),
                          onPressed: widget.onHide,
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('HIDE',
                                semanticsLabel: 'Hide keyboard',
                                style: TextStyle(fontSize: 10, height: 1)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                      child: Row(children: first.map(characterKey).toList())),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(children: second.map(characterKey).toList()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Row(children: [
                      Expanded(
                        flex: 2,
                        child: keyButton(
                          id: 'shift',
                          label: symbols
                              ? (alternateSymbols ? '123' : '#+=')
                              : 'Shift',
                          tooltip: symbols ? 'More symbols' : 'Shift',
                          icon: symbols ? null : Icons.arrow_upward,
                          selected: symbols ? alternateSymbols : uppercase,
                          onPressed: () => setState(() {
                            if (symbols) {
                              alternateSymbols = !alternateSymbols;
                            } else {
                              uppercase = !uppercase;
                            }
                          }),
                        ),
                      ),
                      ...third.map((character) => Expanded(
                          flex: 2,
                          child: keyButton(
                              id: 'key-$character',
                              label: character,
                              onPressed: () => insert(character)))),
                      Expanded(
                        flex: 2,
                        child: keyButton(
                          id: 'backspace',
                          label: 'DEL',
                          tooltip: 'Backspace',
                          onPressed: backspace,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Row(children: [
                      Expanded(
                        flex: 2,
                        child: keyButton(
                          id: 'symbols',
                          label: symbols ? 'ABC' : '123',
                          tooltip: symbols ? 'Letters' : 'Numbers and symbols',
                          onPressed: () => setState(() {
                            symbols = !symbols;
                            alternateSymbols = false;
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: keyButton(
                            id: 'space',
                            label: 'space',
                            tooltip: 'Space',
                            onPressed: () => insert(' ')),
                      ),
                      Expanded(
                        flex: 2,
                        child: keyButton(
                          id: 'return',
                          label: 'RETURN',
                          tooltip: 'New line',
                          onPressed: () => insert('\n'),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
