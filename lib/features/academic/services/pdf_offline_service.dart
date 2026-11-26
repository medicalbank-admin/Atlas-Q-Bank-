import 'package:http/http.dart' as http;
import '../models/learning_resource_model.dart';
import 'pdf_offline_store.dart';

class PdfOfflineService {
  static Future<void> download(LearningResourceModel resource, {
    void Function(int received, int total)? onProgress,
  }) async {
    final uri = Uri.tryParse(resource.resourceUrl);
    if (uri == null || !uri.hasScheme || !['http', 'https'].contains(uri.scheme)) {
      throw Exception('This PDF has an invalid download address.');
    }
    final request = http.Request('GET', uri);
    final response = await http.Client().send(request).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('PDF download failed (HTTP ${response.statusCode}).');
    final total = response.contentLength ?? 0;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      onProgress?.call(bytes.length, total);
    }
    if (bytes.isEmpty) throw Exception('The downloaded PDF is empty.');
    final data = Uint8List.fromList(bytes);
    if (data.length < 5 || String.fromCharCodes(data.take(5)) != '%PDF-') {
      throw Exception('The link did not return a valid PDF file.');
    }
    await saveOfflinePdf(resource.id, data, {
      'title': resource.title,
      'resourceUrl': resource.resourceUrl,
      'subjectName': resource.subjectName,
      'systemName': resource.systemName,
      'topicName': resource.topicName,
      'versionNumber': resource.versionNumber,
      'updatedAt': resource.updatedAt.toIso8601String(),
    });
  }
}
