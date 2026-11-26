import 'package:shared_preferences/shared_preferences.dart';

String _key(String id) => 'atlas_offline_chapter_${id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

Future<void> saveOfflineChapter(String id, String content) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = await prefs.setString(_key(id), content);
  if (!saved) {
    throw Exception('Browser storage is full. Remove unused offline chapters and try again.');
  }
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

Future<List<String>> listOfflineChapterIds() async {
  final prefs = await SharedPreferences.getInstance();
  const prefix = 'atlas_offline_chapter_';
  return prefs.getKeys().where((key) => key.startsWith(prefix))
      .map((key) => key.substring(prefix.length)).toList();
}
