import 'package:file_picker/file_picker.dart';

class PickedMedia {
  final List<int> bytes;
  final String name;
  PickedMedia(this.bytes, this.name);
}

class MediaPicker {
  static Future<PickedMedia?> pickVideo() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    final f = r?.files.single;
    if (f == null || f.bytes == null) return null;
    return PickedMedia(f.bytes!.toList(), f.name);
  }

  static Future<PickedMedia?> pickImage() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final f = r?.files.single;
    if (f == null || f.bytes == null) return null;
    return PickedMedia(f.bytes!.toList(), f.name);
  }
}