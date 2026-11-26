import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

String _key(String id) => 'atlas_offline_pdf_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
Future<void> saveOfflinePdf(String id, Uint8List bytes, Map<String, dynamic> metadata) async {
  final prefs = await SharedPreferences.getInstance();
  final value = jsonEncode({...metadata, 'id': id, 'sizeBytes': bytes.length,
    'savedAt': DateTime.now().toIso8601String(), 'bytes': base64Encode(bytes)});
  if (!await prefs.setString(_key(id), value)) {
    throw Exception('Browser storage is full. Remove unused offline PDFs and try again.');
  }
}
Future<Uint8List?> readOfflinePdf(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_key(id));
  if (raw == null) return null;
  final data = jsonDecode(raw);
  return data is Map && data['bytes'] is String
      ? base64Decode(data['bytes'] as String) : null;
}
Future<void> removeOfflinePdf(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_key(id));
}
Future<bool> hasOfflinePdf(String id) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(_key(id));
}
Future<List<Map<String, dynamic>>> listOfflinePdfs() async {
  final prefs = await SharedPreferences.getInstance();
  const prefix = 'atlas_offline_pdf_';
  final items = <Map<String, dynamic>>[];
  for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
    try {
      final data = jsonDecode(prefs.getString(key)!);
      if (data is Map) {
        final item = Map<String, dynamic>.from(data)..remove('bytes');
        items.add(item);
      }
    } catch (_) {}
  }
  return items;
}
