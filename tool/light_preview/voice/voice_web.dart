import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'voice_capture.dart';

LocalVoiceCapture createLocalVoiceCapture() => _BrowserVoiceCapture();

class _BrowserVoiceCapture implements LocalVoiceCapture {
  html.MediaStream? _stream;
  html.MediaRecorder? _recorder;
  StreamSubscription<html.BlobEvent>? _dataSubscription;
  List<html.Blob> _chunks = [];
  final Stopwatch _watch = Stopwatch();
  int _session = 0;
  html.AudioElement? _audio;
  String? _playbackUrl;
  Completer<void>? _playbackDone;
  StreamSubscription<html.Event>? _playbackEnded;
  StreamSubscription<html.Event>? _playbackError;

  @override
  Future<void> start() async {
    cancel();
    stopPlayback();
    final session = ++_session;
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      throw UnsupportedError(
          'Microphone access needs localhost or a secure browser page.');
    }
    // This is reached only after the user explicitly presses the microphone.
    final stream = await devices.getUserMedia({'audio': true});
    if (session != _session) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      throw StateError('Recording canceled.');
    }
    _stream = stream;
    try {
      final supported = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4']
          .where(html.MediaRecorder.isTypeSupported);
      final recorder = supported.isEmpty
          ? html.MediaRecorder(stream)
          : html.MediaRecorder(stream, {'mimeType': supported.first});
      _recorder = recorder;
      final chunks = <html.Blob>[];
      _chunks = chunks;
      _dataSubscription =
          const html.EventStreamProvider<html.BlobEvent>('dataavailable')
              .forTarget(recorder)
              .listen((event) {
        if (event.data != null && event.data!.size > 0) chunks.add(event.data!);
      });
      recorder.start();
      _watch
        ..reset()
        ..start();
    } catch (_) {
      cancel();
      rethrow;
    }
  }

  @override
  Future<LocalVoiceClip> stop() async {
    final recorder = _recorder;
    if (recorder == null || recorder.state != 'recording') {
      throw StateError('No recording is active.');
    }
    final session = _session;
    final stream = _stream;
    final subscription = _dataSubscription;
    final chunks = _chunks;
    final stopped = const html.EventStreamProvider<html.Event>('stop')
        .forTarget(recorder)
        .first;
    _watch.stop();
    final duration = _watch.elapsed;
    recorder.stop();
    try {
      await stopped.timeout(const Duration(seconds: 10));
      if (session != _session) throw StateError('Recording canceled.');
      final mime = recorder.mimeType ?? 'audio/webm';
      final blob = html.Blob(chunks, mime);
      if (blob.size == 0)
        throw StateError('No audio was captured. Please try again.');
      final reader = html.FileReader();
      final loaded = reader.onLoad.first;
      reader.readAsArrayBuffer(blob);
      await loaded.timeout(const Duration(seconds: 10));
      if (session != _session) throw StateError('Recording canceled.');
      final result = reader.result;
      final bytes =
          result is ByteBuffer ? Uint8List.view(result) : result as Uint8List;
      return LocalVoiceClip(bytes: bytes, mimeType: mime, duration: duration);
    } finally {
      for (final track in stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
        track.stop();
      }
      await subscription?.cancel();
      // A canceled stop may finish after a new recording has already begun.
      if (identical(_recorder, recorder)) {
        _stream = null;
        _dataSubscription = null;
        _recorder = null;
        _chunks = [];
      }
    }
  }

  void _releaseTracks() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
  }

  @override
  void cancel() {
    _session++;
    _watch.stop();
    if (_recorder?.state == 'recording') _recorder!.stop();
    _recorder = null;
    _releaseTracks();
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _chunks = [];
  }

  @override
  Future<void> play(LocalVoiceClip clip) async {
    stopPlayback();
    final url = html.Url.createObjectUrlFromBlob(
        html.Blob([clip.bytes], clip.mimeType));
    _playbackUrl = url;
    final audio = html.AudioElement(url);
    _audio = audio;
    final done = Completer<void>();
    _playbackDone = done;
    _playbackEnded = audio.onEnded.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    _playbackError = audio.onError.listen((_) {
      if (!done.isCompleted)
        done.completeError(StateError('Audio playback failed.'));
    });
    try {
      await Future.wait([audio.play(), done.future], eagerError: true);
    } finally {
      if (identical(_audio, audio)) stopPlayback();
    }
  }

  @override
  void stopPlayback() {
    _audio?.pause();
    _audio = null;
    _playbackEnded?.cancel();
    _playbackEnded = null;
    _playbackError?.cancel();
    _playbackError = null;
    if (_playbackUrl != null) html.Url.revokeObjectUrl(_playbackUrl!);
    _playbackUrl = null;
    if (_playbackDone != null && !_playbackDone!.isCompleted)
      _playbackDone!.complete();
    _playbackDone = null;
  }

  @override
  void dispose() {
    cancel();
    stopPlayback();
  }
}
