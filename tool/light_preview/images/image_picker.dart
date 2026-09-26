import 'dart:typed_data';

const maxLocalImageBytes = 20 * 1024 * 1024;
const maxLocalImagesPerPick = 10;

/// Image bytes remain in memory; picking never uploads a file.
class LocalImage {
  const LocalImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Invoke [pick] directly from a user action so browser activation is preserved.
abstract class LocalImagePicker {
  Future<List<LocalImage>> pick();
  void dispose();
}

class LocalImagePickerException implements Exception {
  const LocalImagePickerException(this.message);

  final String message;

  @override
  String toString() => message;
}
