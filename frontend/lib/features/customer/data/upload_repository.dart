import 'dart:io';

import 'api_helper.dart';

class UploadRepository {
  Future<String> getPresignedUrl(String fileName, String mimeType, String folder) async {
    final path = '$folder/${sb.user!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await sb.client.storage.from('uploads').createSignedUploadUrl(path);
    final url = sb.client.storage.from('uploads').getPublicUrl(path);
    return url;
  }

  Future<String> uploadFile(dynamic file, String folder, void Function(double)? onProgress) async {
    final path = '$folder/${sb.user!.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    onProgress?.call(0);
    await sb.client.storage.from('uploads').upload(path, File(file.path as String));
    onProgress?.call(1);
    return sb.client.storage.from('uploads').getPublicUrl(path);
  }
}
