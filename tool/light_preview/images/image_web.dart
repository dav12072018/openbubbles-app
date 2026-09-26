import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker.dart';

LocalImagePicker createLocalImagePicker() => _BrowserImagePicker();

class _BrowserImagePicker implements LocalImagePicker {
  _ImageSelection? _active;
  bool _disposed = false;

  @override
  Future<List<LocalImage>> pick() {
    if (_disposed) return Future.value(const []);
    final active = _active;
    if (active != null) return active.done.future;
    final selection = _ImageSelection((finished) {
      if (identical(_active, finished)) _active = null;
    });
    _active = selection;
    // Keep this call synchronous with the original button click.
    selection.open();
    return selection.done.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _active?.cancel();
  }
}

/// Every picker invocation owns its DOM node, timers and FileReaders.
class _ImageSelection {
  _ImageSelection(this.onFinished);

  final void Function(_ImageSelection) onFinished;
  final done = Completer<List<LocalImage>>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true
    ..style.display = 'none';
  final _events = <StreamSubscription<html.Event>>[];
  final _readerEvents = <StreamSubscription<html.ProgressEvent>>[];
  Timer? _returnTimer;
  Timer? _readTimer;
  html.FileReader? _reader;
  Completer<Uint8List>? _readDone;
  bool _reading = false;
  bool _finished = false;

  void open() {
    _events.add(input.onChange.listen((_) => _chooseFiles()));
    _events.add(const html.EventStreamProvider<html.Event>('cancel')
        .forTarget(input)
        .listen((_) => cancel()));
    // Older browsers may report dialog cancellation only by returning focus.
    // Give change/file-list updates time to arrive before treating it as empty.
    _events.add(html.window.onFocus.listen((_) => _returnedToPage()));
    _events.add(html.document.onVisibilityChange.listen((_) {
      if (html.document.visibilityState == 'visible') _returnedToPage();
    }));
    try {
      html.document.body?.append(input);
      input.click();
    } catch (_) {
      _finish(
          error: const LocalImagePickerException(
              'The browser could not open the image picker. Please try again.'));
    }
  }

  void _returnedToPage() {
    if (_finished || _reading) return;
    _returnTimer?.cancel();
    _returnTimer = Timer(const Duration(milliseconds: 500), () {
      if (_finished || _reading) return;
      if (input.files?.isNotEmpty ?? false) {
        _chooseFiles();
      } else {
        cancel();
      }
    });
  }

  void _chooseFiles() {
    if (_finished || _reading) return;
    _returnTimer?.cancel();
    final files = List<html.File>.of(input.files ?? const []);
    if (files.isEmpty) {
      cancel();
      return;
    }
    _reading = true;
    _loadFiles(files);
  }

  Future<void> _loadFiles(List<html.File> files) async {
    try {
      if (files.length > maxLocalImagesPerPick) {
        throw const LocalImagePickerException(
            'Choose up to 10 images at a time.');
      }
      for (final file in files) {
        final knownImageExtension = RegExp(
                r'\.(jpe?g|png|gif|webp|bmp|tiff?|heic|heif|avif|ico)$',
                caseSensitive: false)
            .hasMatch(file.name);
        if (!file.type.startsWith('image/') &&
            !(file.type.isEmpty && knownImageExtension)) {
          throw LocalImagePickerException(
              '${file.name} is not an image. Choose an image file.');
        }
        if (file.size == 0) {
          throw LocalImagePickerException('${file.name} is empty.');
        }
        if (file.size > maxLocalImageBytes) {
          throw LocalImagePickerException(
              '${file.name} is too large. Each image must be 20 MiB or smaller.');
        }
      }
      final images = <LocalImage>[];
      for (final file in files) {
        final bytes = await _readFile(file);
        if (_finished) return;
        images.add(LocalImage(bytes: bytes, name: file.name));
      }
      _finish(images: images);
    } catch (error) {
      if (!_finished) {
        _finish(
            error: error is LocalImagePickerException
                ? error
                : const LocalImagePickerException(
                    'The image could not be read. Please choose it again.'));
      }
    }
  }

  Future<Uint8List> _readFile(html.File file) {
    final reader = html.FileReader();
    final readDone = Completer<Uint8List>();
    _reader = reader;
    _readDone = readDone;

    void fail() {
      if (!readDone.isCompleted) {
        readDone.completeError(
            LocalImagePickerException('${file.name} could not be read.'));
      }
    }

    _readerEvents.add(reader.onLoad.listen((_) {
      if (readDone.isCompleted) return;
      final result = reader.result;
      if (result is ByteBuffer) {
        readDone.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        readDone.complete(result);
      } else {
        fail();
      }
    }));
    _readerEvents.add(reader.onError.listen((_) => fail()));
    _readerEvents.add(reader.onAbort.listen((_) => fail()));
    _readTimer = Timer(const Duration(seconds: 30), fail);
    try {
      reader.readAsArrayBuffer(file);
    } catch (_) {
      fail();
    }
    return readDone.future.whenComplete(_clearReader);
  }

  void _clearReader() {
    _readTimer?.cancel();
    _readTimer = null;
    for (final subscription in _readerEvents) {
      subscription.cancel();
    }
    _readerEvents.clear();
    final reader = _reader;
    _reader = null;
    _readDone = null;
    if (reader?.readyState == html.FileReader.LOADING) reader!.abort();
  }

  void cancel() => _finish();

  void _finish({List<LocalImage> images = const [], Object? error}) {
    if (_finished) return;
    _finished = true;
    _returnTimer?.cancel();
    // Wake the internal read loop before detaching/aborting its reader.
    final readDone = _readDone;
    if (readDone != null && !readDone.isCompleted) {
      readDone.completeError(
          const LocalImagePickerException('Image selection canceled.'));
    }
    _clearReader();
    for (final subscription in _events) {
      subscription.cancel();
    }
    _events.clear();
    input.remove();
    onFinished(this);
    if (error == null) {
      done.complete(List<LocalImage>.unmodifiable(images));
    } else {
      done.completeError(error);
    }
  }
}
