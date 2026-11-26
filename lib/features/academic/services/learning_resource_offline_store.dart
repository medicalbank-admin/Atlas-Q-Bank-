import 'learning_resource_offline_store_io.dart'
    if (dart.library.html) 'learning_resource_offline_store_web.dart' as platform;

Future<void> saveOfflineChapter(String id, String content) =>
    platform.saveOfflineChapter(id, content);

Future<String?> readOfflineChapter(String id) =>
    platform.readOfflineChapter(id);

Future<void> removeOfflineChapter(String id) =>
    platform.removeOfflineChapter(id);

Future<bool> hasOfflineChapter(String id) =>
    platform.hasOfflineChapter(id);
