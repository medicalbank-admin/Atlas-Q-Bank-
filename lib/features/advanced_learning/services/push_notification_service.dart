import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Device registration is client-side; FCM message delivery is server-side.
class PushNotificationService {
  static const String _apiUrl = String.fromEnvironment('PUSH_API_URL', defaultValue: 'https://atlas-academy-push-api.medicalbankadmin.workers.dev');
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;

  Future<int> sendAnnouncement({
    required String title,
    required String body,
    String? userId,
  }) async {
    if (_apiUrl.trim().isEmpty) {
      throw Exception('Push service endpoint is not configured in this app build.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Administrator sign-in is required.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your administrator session could not be verified.');
    }
    final endpoint = _apiUrl.endsWith('/') ? '${_apiUrl}send' : '$_apiUrl/send';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      }),
    ).timeout(const Duration(seconds: 30));
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded is! Map ||
        decoded['success'] != true) {
      throw Exception(decoded is Map
          ? (decoded['message'] ?? 'Push delivery failed.').toString()
          : 'Push service returned an invalid response.');
    }
    return (decoded['sent'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> sendCampaign({
    required String notificationId,
    required String title,
    required String body,
    String imageUrl = '',
    String destination = '',
    String audience = 'all',
    String membershipPlan = '',
    String medicalPathway = '',
    String subscriptionStatus = 'active',
    List<String> userIds = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Administrator sign-in is required.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Administrator session could not be verified.');
    final endpoint = _apiUrl.endsWith('/') ? '${_apiUrl}send' : '$_apiUrl/send';
    final response = await http.post(Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'notificationId': notificationId, 'title': title, 'body': body,
        'imageUrl': imageUrl, 'destination': destination, 'audience': audience,
        'membershipPlan': membershipPlan, 'medicalPathway': medicalPathway,
        'subscriptionStatus': subscriptionStatus, 'userIds': userIds,
      })).timeout(const Duration(seconds: 60));
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map || decoded['success'] != true) {
      throw Exception(decoded is Map ? (decoded['message'] ?? 'Push delivery failed.').toString() : 'Invalid push response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> registerDevice(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _save(user.uid, token);
      _refresh ??= messaging.onTokenRefresh.listen(
        (value) => _save(user.uid, value),
      );
      _foreground ??= FirebaseMessaging.onMessage.listen((message) {
        if (!context.mounted) return;
        final title = message.notification?.title ?? 'The Atlas Academy';
        final body = message.notification?.body ?? 'You have a new notification.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title: $body')),
        );
      });
    } catch (_) {
      // Push registration is optional if permission or network is unavailable.
    }
  }

  Future<void> _save(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('user_device_tokens')
        .doc(token)
        .set({
      'userId': uid,
      'token': token,
      'platform': 'flutter',
      'updatedAt': FieldValue.serverTimestamp(),
      'active': true,
    }, SetOptions(merge: true));
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('user_device_tokens')
            .doc(token)
            .delete();
      }
    } catch (_) {}
    await _refresh?.cancel();
    _refresh = null;
    await _foreground?.cancel();
    _foreground = null;
  }
}
