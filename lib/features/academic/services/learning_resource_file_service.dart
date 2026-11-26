import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Uploads PDF and video learning resources directly to Cloudinary using
/// short-lived, administrator-only signatures issued by the academy worker.
/// Firebase Storage is deliberately not used.
class LearningResourceFileService {
  static const String _workerBaseUrl = String.fromEnvironment('MCQ_API_URL');

  static Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String resourceType,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.isEmpty) throw Exception('The selected file is empty.');
    if (!['raw', 'video'].contains(resourceType)) {
      throw Exception('Unsupported learning resource type.');
    }
    const maxBytes = 100 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw Exception('This file exceeds the 100 MB upload limit. Please compress it and try again.');
    }

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (resourceType == 'raw' && extension != 'pdf') {
      throw Exception('Please select a PDF document.');
    }
    if (resourceType == 'video' &&
        !['mp4', 'mov', 'm4v', 'webm'].contains(extension)) {
      throw Exception('Please select an MP4, MOV, M4V or WEBM video.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    final baseUrl = _workerBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw Exception('The secure learning upload service is not configured in this app build.');
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Your sign-in could not be verified. Please sign in again.');
    }

    final signatureResponse = await http.post(
      Uri.parse('$baseUrl/notes/upload-signature'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'resourceType': resourceType,
        'extension': extension,
      }),
    ).timeout(const Duration(seconds: 45));

    Map<String, dynamic> signatureData;
    try {
      final decoded = jsonDecode(signatureResponse.body);
      if (decoded is! Map) throw const FormatException();
      signatureData = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('The secure upload service returned an invalid response.');
    }

    if (signatureResponse.statusCode < 200 ||
        signatureResponse.statusCode >= 300 ||
        signatureData['success'] != true) {
      throw Exception(signatureData['message']?.toString() ??
          'The learning file upload could not be authorized.');
    }

    final cloudName = signatureData['cloudName']?.toString() ?? '';
    final apiKey = signatureData['apiKey']?.toString() ?? '';
    final timestamp = signatureData['timestamp']?.toString() ?? '';
    final folder = signatureData['folder']?.toString() ?? '';
    final publicId = signatureData['publicId']?.toString() ?? '';
    final signature = signatureData['signature']?.toString() ?? '';
    final signedType = signatureData['resourceType']?.toString() ?? '';

    if (cloudName.isEmpty || apiKey.isEmpty || timestamp.isEmpty ||
        folder != 'atlas-notes' || publicId.isEmpty || signature.isEmpty ||
        signedType != resourceType) {
      throw Exception('The upload service returned incomplete or mismatched credentials.');
    }

    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final endpoint = resourceType == 'raw' ? 'raw' : 'video';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$endpoint/upload'),
    );
    request.fields.addAll({
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      'folder': folder,
      'public_id': publicId,
      'overwrite': 'false',
    });
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: safeName.isEmpty ? 'learning_resource.$extension' : safeName,
    ));

    final client = http.Client();
    try {
      onProgress?.call(0.05);
      final streamed = await client.send(request)
          .timeout(const Duration(minutes: 8));
      final response = await http.Response.fromStream(streamed);
      Map<String, dynamic> result;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) throw const FormatException();
        result = Map<String, dynamic>.from(decoded);
      } catch (_) {
        throw Exception('Cloudinary returned an unreadable upload response (HTTP ${response.statusCode}).');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = result['error'];
        throw Exception(error is Map
            ? (error['message']?.toString() ?? 'The learning file upload failed.')
            : 'The learning file upload failed (HTTP ${response.statusCode}).');
      }

      final uploadedId = result['public_id']?.toString() ?? '';
      final secureUrl = result['secure_url']?.toString() ?? '';
      final expectedPrefix = 'https://res.cloudinary.com/$cloudName/$endpoint/upload/';
      if (uploadedId != publicId && uploadedId != '$folder/$publicId') {
        throw Exception('Cloudinary returned an unexpected learning file reference.');
      }
      if (!secureUrl.startsWith(expectedPrefix)) {
        throw Exception('Cloudinary returned an invalid secure file address.');
      }
      onProgress?.call(1);
      return secureUrl;
    } finally {
      client.close();
    }
  }
}
