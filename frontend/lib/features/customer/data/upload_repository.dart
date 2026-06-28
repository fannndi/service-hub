import 'dart:io';
import 'package:path/path.dart' as p;

import 'api_helper.dart';

class UploadRepository {
  String _buildPath(String uid, String fileName, String folder) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$uid/${folder}_$ts/$safe';
  }

  Future<String> getPresignedUrl(String fileName, String mimeType, String folder) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final path = _buildPath(uid, fileName, folder);
    await sb.client.storage.from('uploads').createSignedUploadUrl(path);
    return sb.client.storage.from('uploads').getPublicUrl(path);
  }

  Future<String> uploadFile(dynamic file, String folder, void Function(double)? onProgress) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final name = file is File ? p.basename(file.path) : 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final path = _buildPath(uid, name, folder);
    onProgress?.call(0);
    await sb.client.storage.from('uploads').upload(path, File(file.path as String));
    onProgress?.call(1);
    return sb.client.storage.from('uploads').getPublicUrl(path);
  }
}