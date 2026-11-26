import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

String _safe(String id) => id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
Future<Directory> _folder() async {
  final root = await getApplicationSupportDirectory();
  final folder = Directory('${root.path}/atlas_offline_pdfs');
  if (!await folder.exists()) await folder.create(recursive: true);
  return folder;
}
Future<File> _pdf(String id) async => File('${(await _folder()).path}/${_safe(id)}.pdf');
Future<File> _meta(String id) async => File('${(await _folder()).path}/${_safe(id)}.json');

Future<void> saveOfflinePdf(String id, Uint8List bytes, Map<String, dynamic> metadata) async {
  final file = await _pdf(id);
  await file.writeAsBytes(bytes, flush: true);
  await (await _meta(id)).writeAsString(jsonEncode({...metadata, 'id': id, 'sizeBytes': bytes.length, 'savedAt': DateTime.now().toIso8601String()}), flush: true);
}
Future<Uint8List?> readOfflinePdf(String id) async {
  final file = await _pdf(id);
  return await file.exists() ? file.readAsBytes() : null;
}
Future<void> removeOfflinePdf(String id) async {
  final file = await _pdf(id); final meta = await _meta(id);
  if (await file.exists()) await file.delete();
  if (await meta.exists()) await meta.delete();
}
Future<bool> hasOfflinePdf(String id) async => (await _pdf(id)).exists();
Future<List<Map<String, dynamic>>> listOfflinePdfs() async {
  final folder = await _folder(); final items = <Map<String, dynamic>>[];
  await for (final entity in folder.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final data = jsonDecode(await entity.readAsString());
        if (data is Map) items.add(Map<String, dynamic>.from(data));
      } catch (_) {}
    }
  }
  return items;
}
