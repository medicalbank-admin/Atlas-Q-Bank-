import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSecurityException implements Exception {
  const DeviceSecurityException(this.message, {this.replaced = false});
  final String message;
  final bool replaced;
  @override
  String toString() => message;
}

class DeviceSecurityService {
  static const String _apiUrl =
      'https://atlas-academy-push-api.medicalbankadmin.workers.dev';

  Future<String> _deviceId() async {
    final preferences = await SharedPreferences.getInstance();
    var id = preferences.getString('atlas_installation_device_id');
    if (id == null || id.length < 24) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      id = base64UrlEncode(bytes).replaceAll('=', '');
      await preferences.setString('atlas_installation_device_id', id);
    }
    return id;
  }

  Future<Map<String, dynamic>> _call(String action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const DeviceSecurityException('Please sign in again.');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const DeviceSecurityException('Your sign-in could not be verified.');
    }
    final id = await _deviceId();
    final response = await http.post(
      Uri.parse('$_apiUrl/device/$action'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'deviceId': id,
        'platform': defaultTargetPlatform.name,
        'deviceLabel': defaultTargetPlatform == TargetPlatform.android
            ? 'Android app installation'
            : 'iOS app installation',
      }),
    ).timeout(const Duration(seconds: 20));
    final dynamic result = jsonDecode(response.body);
    if (result is! Map || result['success'] != true) {
      throw DeviceSecurityException(
        result is Map
            ? (result['message'] ?? 'Device security check failed.').toString()
            : 'Device security service returned an invalid response.',
        replaced: result is Map && result['code'] == 'device_replaced',
      );
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> registerCurrentDevice() => _call('register');

  Future<void> validateCurrentDevice() async {
    await _call('validate');
  }
}
