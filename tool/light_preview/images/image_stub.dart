import 'image_picker.dart';

LocalImagePicker createLocalImagePicker() => _UnavailableImagePicker();

class _UnavailableImagePicker implements LocalImagePicker {
  @override
  Future<List<LocalImage>> pick() async =>
      throw const LocalImagePickerException(
          'Open the web demo in a browser to choose local images.');

  @override
  void dispose() {}
}
