import 'dart:typed_data';

class LocalVoiceClip {
  const LocalVoiceClip(
      {required this.bytes, required this.mimeType, required this.duration});
  final Uint8List bytes;
  final String mimeType;
  final Duration duration;
}

/// Audio exists only in browser memory; implementations never upload it.
abstract class LocalVoiceCapture {
  Future<void> start();
  Future<LocalVoiceClip> stop();
  void cancel();
  Future<void> play(LocalVoiceClip clip);
  void stopPlayback();
  void dispose();
}
