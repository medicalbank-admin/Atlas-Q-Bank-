import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_resource_model.dart';
import 'learning_resource_offline_store.dart';

class LearningResourceOfflineService {
  static Future<void> download(LearningResourceModel resource) async {
    final blocks = <Map<String, dynamic>>[];
    for (final original in resource.contentBlocks) {
      final block = Map<String, dynamic>.from(original);
      if (block['type'] == 'image') {
        final url = (block['imageUrl'] ?? '').toString();
        if (url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri == null || !uri.hasScheme ||
              !['http', 'https'].contains(uri.scheme)) {
            throw Exception('A chapter image has an invalid address.');
          }
          final response = await http.get(uri).timeout(const Duration(seconds: 45));
          if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
            throw Exception('An image could not be downloaded. Please retry.');
          }
          final mime = response.headers['content-type'] ?? 'image/jpeg';
          block['offlineImageData'] =
              'data:$mime;base64,${base64Encode(response.bodyBytes)}';
        }
      }
      blocks.add(block);
    }
    final payload = <String, dynamic>{
      'id': resource.id,
      'title': resource.title,
      'description': resource.description,
      'systemName': resource.systemName,
      'readingMinutes': resource.readingMinutes,
      'textContent': resource.textContent,
      'contentBlocks': blocks,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await saveOfflineChapter(resource.id, jsonEncode(payload));
  }

  static Future<Map<String, dynamic>?> read(String id) async {
    final raw = await readOfflineChapter(id);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<void> remove(String id) => removeOfflineChapter(id);
  static Future<bool> isSaved(String id) => hasOfflineChapter(id);
}
