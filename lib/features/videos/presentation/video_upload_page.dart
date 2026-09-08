import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/media_picker.dart';

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({super.key, required this.isShort});
  final bool isShort;

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final picked = await MediaPicker.pickVideo();
    if (picked == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final res = await CloudinaryService.uploadVideo(picked.bytes, picked.name);
      if (mounted) {
        context.pushReplacement('/editor', extra: {
          'url': res['url'],
          'public_id': res['public_id'],
          'is_short': widget.isShort,
        });
      }
    } catch (e) {
      setState(() => _error = 'Upload ব্যর্থ: $e');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isShort ? '📱 Create Short' : '🎬 Upload Video'),
      ),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_uploading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('☁️ Cloudinary-তে upload হচ্ছে…'),
          ] else ...[
            const Icon(Icons.cloud_upload, size: 64),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _pickAndUpload,
              child: const Text('ভিডিও বেছে নিন'),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ]),
      ),
    );
  }
}