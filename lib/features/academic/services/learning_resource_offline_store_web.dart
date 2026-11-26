import 'package:shared_preferences/shared_preferences.dart';

String _key(String id) => 'atlas_offline_chapter_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

Future<void> saveOfflineChapter(String id, String content) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_key(id), content);
}

Future<String?> readOfflineChapter(String id) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_key(id));
}

Future<void> removeOfflineChapter(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_key(id));
}

Future<bool> hasOfflineChapter(String id) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(_key(id));
}
