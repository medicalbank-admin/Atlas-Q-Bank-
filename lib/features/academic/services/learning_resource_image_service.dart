import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Uploads Notes Studio illustrations through the existing authenticated
/// Cloudflare Worker and Cloudinary account. No Firebase Storage is used.
class LearningResourceImageService {
  static const String _workerBaseUrl = String.fromEnvironment('MCQ_API_URL');

  static Future<String> uploadChapterImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
      throw Exception('Please choose an image smaller than 12 MB.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');

    final baseUrl = _workerBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw Exception('The secure image service is not configured in this app build.');
    }

    final token = await user.getIdToken();
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
      body: jsonEncode(<String, dynamic>{}),
    ).timeout(const Duration(seconds: 45));

    Map<String, dynamic> signatureData;
    try {
      final decoded = jsonDecode(signatureResponse.body);
      if (decoded is! Map) throw const FormatException();
      signatureData = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw Exception('The secure image service returned an invalid response.');
    }

    if (signatureResponse.statusCode < 200 ||
        signatureResponse.statusCode >= 300 ||
        signatureData['success'] != true) {
      throw Exception(signatureData['message']?.toString() ??
          'The chapter image upload could not be authorized.');
    }

    final cloudName = signatureData['cloudName']?.toString() ?? '';
    final apiKey = signatureData['apiKey']?.toString() ?? '';
    final timestamp = signatureData['timestamp']?.toString() ?? '';
    final folder = signatureData['folder']?.toString() ?? '';
    final publicId = signatureData['publicId']?.toString() ?? '';
    final uploadSignature = signatureData['signature']?.toString() ?? '';

    if (cloudName.isEmpty || apiKey.isEmpty || timestamp.isEmpty ||
        folder != 'atlas-notes' || publicId.isEmpty || uploadSignature.isEmpty) {
      throw Exception('The image service returned incomplete upload credentials.');
    }

    final normalizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final safeName = normalizedName.isEmpty ? 'medical_image.jpg' : normalizedName;
    final uploadName = safeName.contains('.') ? safeName : '$safeName.jpg';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );
    request.fields.addAll({
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': uploadSignature,
      'folder': folder,
      'public_id': publicId,
      'overwrite': 'false',
    });
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: uploadName,
    ));

    final client = http.Client();
    try {
      final streamed = await client.send(request)
          .timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      Map<String, dynamic> result;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) throw const FormatException();
        result = Map<String, dynamic>.from(decoded);
      } catch (_) {
        throw Exception('Cloudinary returned an unreadable upload response '
            '(HTTP ${response.statusCode}).');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = result['error'];
        throw Exception(error is Map
            ? (error['message']?.toString() ?? 'Image upload failed.')
            : 'Image upload failed (HTTP ${response.statusCode}).');
      }

      final uploadedId = result['public_id']?.toString() ?? '';
      final expectedId = '$folder/$publicId';
      final secureUrl = result['secure_url']?.toString() ?? '';
      final expectedPrefix = 'https://res.cloudinary.com/$cloudName/image/upload/';
      if ((uploadedId != publicId && uploadedId != expectedId) ||
          !secureUrl.startsWith(expectedPrefix)) {
        throw Exception('Cloudinary returned an unexpected chapter image address.');
      }
      return secureUrl;
    } finally {
      client.close();
    }
  }
}
