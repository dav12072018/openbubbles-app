import 'package:flutter/material.dart';

/// Explicit, finger-sized voice actions for the compact Light composer.
class LightVoiceNoteControls extends StatelessWidget {
  const LightVoiceNoteControls({
    super.key,
    required this.recording,
    required this.onRecord,
    required this.onStop,
    required this.onCancel,
    this.busy = false,
  });

  final bool recording;
  final bool busy;
  final VoidCallback onRecord;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!recording) {
      return SizedBox(
        width: 56,
        height: 48,
        child: IconButton(
          tooltip: 'Record voice note',
          onPressed: busy ? null : onRecord,
          icon: const Icon(Icons.mic_none, size: 26),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: 'Cancel voice note',
            onPressed: busy ? null : onCancel,
            icon: const Icon(Icons.close),
          ),
        ),
        SizedBox(
          width: 56,
          height: 48,
          child: Tooltip(
            message: 'Stop and review voice note',
            child: TextButton(
              onPressed: busy ? null : onStop,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('STOP', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
