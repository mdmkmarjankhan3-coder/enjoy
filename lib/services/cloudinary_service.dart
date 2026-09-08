import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class CloudinaryService {
  static Future<Map<String, String>> uploadVideo(List<int> bytes, String filename) =>
      _upload(bytes, filename, 'video');

  static Future<Map<String, String>> uploadImage(List<int> bytes, String filename) =>
      _upload(bytes, filename, 'image');

  static Future<Map<String, String>> uploadFile(List<int> bytes, String filename) =>
      _upload(bytes, filename, 'raw');

  static Future<Map<String, String>> _upload(
      List<int> bytes, String filename, String resourceType) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/$resourceType/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await req.send();
    final body = jsonDecode(await res.stream.bytesToString());
    if (res.statusCode != 200) throw Exception('Cloudinary upload failed');
    return {'url': body['secure_url'], 'public_id': body['public_id']};
  }
}