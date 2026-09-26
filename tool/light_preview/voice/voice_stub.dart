import 'voice_capture.dart';

LocalVoiceCapture createLocalVoiceCapture() => _UnavailableVoiceCapture();

class _UnavailableVoiceCapture implements LocalVoiceCapture {
  @override
  Future<void> start() async => throw UnsupportedError(
      'Open the web demo in a browser to record a voice note.');
  @override
  Future<LocalVoiceClip> stop() async =>
      throw StateError('No recording is active.');
  @override
  void cancel() {}
  @override
  Future<void> play(LocalVoiceClip clip) async =>
      throw UnsupportedError('Audio playback requires a browser.');
  @override
  void stopPlayback() {}
  @override
  void dispose() {}
}
