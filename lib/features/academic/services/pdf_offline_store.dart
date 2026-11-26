import 'pdf_offline_store_io.dart'
    if (dart.library.html) 'pdf_offline_store_web.dart' as platform;
import 'dart:typed_data';

Future<void> saveOfflinePdf(String id, Uint8List bytes,
  Map<String, dynamic> metadata) => platform.saveOfflinePdf(id, bytes, metadata);
Future<Uint8List?> readOfflinePdf(String id) => platform.readOfflinePdf(id);
Future<void> removeOfflinePdf(String id) => platform.removeOfflinePdf(id);
Future<bool> hasOfflinePdf(String id) => platform.hasOfflinePdf(id);
Future<List<Map<String, dynamic>>> listOfflinePdfs() => platform.listOfflinePdfs();
