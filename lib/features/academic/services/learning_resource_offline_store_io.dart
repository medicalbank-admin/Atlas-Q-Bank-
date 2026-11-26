import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> _chapterFile(String id) async {
  final directory = await getApplicationSupportDirectory();
  final folder = Directory('${directory.path}/atlas_offline_chapters');
  if (!await folder.exists()) await folder.create(recursive: true);
  final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return File('${folder.path}/$safeId.json');
}

Future<void> saveOfflineChapter(String id, String content) async {
  final file = await _chapterFile(id);
  await file.writeAsString(content, flush: true);
}

Future<String?> readOfflineChapter(String id) async {
  final file = await _chapterFile(id);
  return await file.exists() ? file.readAsString() : null;
}

Future<void> removeOfflineChapter(String id) async {
  final file = await _chapterFile(id);
  if (await file.exists()) await file.delete();
}

Future<bool> hasOfflineChapter(String id) async {
  final file = await _chapterFile(id);
  return file.exists();
}
