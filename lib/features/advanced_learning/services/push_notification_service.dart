import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Device registration is client-side; FCM message delivery is server-side.
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static Future<void>? _localReady;

  Future<void> _initializeLocalNotifications() {
    return _localReady ??= () async {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _local.initialize(settings);
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        'atlas_academy_updates',
        'Academy Updates',
        description: 'Important learning, membership and academy announcements.',
        importance: Importance.max,
        playSound: true,
      ));
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true,
      );
    }();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      message.notification?.title ?? 'The Atlas Academy',
      message.notification?.body ?? 'You have a new notification.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'atlas_academy_updates',
          'Academy Updates',
          channelDescription: 'Important learning, membership and academy announcements.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static const String _apiUrl = String.fromEnvironment('PUSH_API_URL', defaultValue: 'https://atlas-academy-push-api.medicalbankadmin.workers.dev');
  static const String _webVapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  Future<void> Function(RemoteMessage message)? _notificationTapHandler;

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

  Future<void> sendForumReplyEvent({required String postId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return;
    final endpoint = _apiUrl.endsWith('/') ? '${_apiUrl}event' : '$_apiUrl/event';
    await http.post(Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'type': 'forum_reply', 'postId': postId}),
    ).timeout(const Duration(seconds: 30));
  }

  Future<Map<String, dynamic>> _sendAutomaticEvent(Map<String, dynamic> event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Your sign-in could not be verified.');
    final endpoint = _apiUrl.endsWith('/') ? '${_apiUrl}event' : '$_apiUrl/event';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(event),
    ).timeout(const Duration(seconds: 30));
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        decoded is! Map || decoded['success'] != true) {
      throw Exception(decoded is Map
          ? (decoded['message'] ?? 'Automatic notification failed.').toString()
          : 'Invalid automatic notification response.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<void> sendSubscriptionRequestEvent({required String requestId}) async {
    await _sendAutomaticEvent({'type': 'subscription_request', 'requestId': requestId});
  }

  Future<void> sendSubscriptionDecisionEvent({required String requestId}) async {
    await _sendAutomaticEvent({'type': 'subscription_decision', 'requestId': requestId});
  }

  Future<void> sendInboxMessageEvent({
    required String studentUid,
    required String messageId,
  }) async {
    await _sendAutomaticEvent({
      'type': 'inbox_message',
      'studentUid': studentUid,
      'messageId': messageId,
    });
  }

  Future<void> _recordOpen(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    final notificationId = message.data['notificationId']?.toString() ?? '';
    if (user == null || notificationId.isEmpty) return;
    final destination = message.data['destination']?.toString() ?? '';
    if (destination.startsWith('https://') || destination.startsWith('http://')) {
      final uri = Uri.tryParse(destination);
      if (uri != null) { try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {} }
    }
    try {
      await FirebaseFirestore.instance.collection('push_notification_events').add({
        'notificationId': notificationId,
        'userId': user.uid,
        'event': 'opened',
        'destination': message.data['destination']?.toString() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> registerDevice(BuildContext context, {Future<void> Function(RemoteMessage message)? onNotificationTap}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (kIsWeb) {
      await _registerWebDevice(user.uid, requestPermission: false, onNotificationTap: onNotificationTap);
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await _initializeLocalNotifications();
      final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _save(user.uid, token);
      _attachMessageListeners(messaging, onNotificationTap);
    } catch (error, stackTrace) {
      debugPrint('Atlas Academy push registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Checks the OS/browser permission and registers this device without prompting.
  /// Returns true only after an FCM token is successfully saved.
  Future<bool> checkAndRegisterNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      if (kIsWeb) {
        return _registerWebDevice(user.uid, requestPermission: false);
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return false;
      }
      await _initializeLocalNotifications();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return false;
      await _save(user.uid, token);
      _attachMessageListeners(messaging, null);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Atlas Academy notification status check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Requests permission after an explicit student action, then registers FCM.
  Future<bool> requestAndRegisterNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    if (kIsWeb) return enableWebNotifications(context);
    final messaging = FirebaseMessaging.instance;
    await _initializeLocalNotifications();
    final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('The device did not provide a notification registration token.');
    }
    await _save(user.uid, token);
    _attachMessageListeners(messaging, null);
    return true;
  }

  /// Must be called directly from a user tap on web, especially for iOS Home Screen apps.
  Future<bool> enableWebNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in again.');
    if (!kIsWeb) return false;
    if (_webVapidKey.trim().isEmpty) {
      throw Exception('Web notifications are not configured yet. Please try again after the academy completes notification setup.');
    }
    return _registerWebDevice(user.uid, requestPermission: true);
  }

  Future<bool> _registerWebDevice(
    String uid, {
    required bool requestPermission,
    Future<void> Function(RemoteMessage message)? onNotificationTap,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = requestPermission
          ? await messaging.requestPermission(alert: true, badge: true, sound: true)
          : await messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return false;
      }
      if (_webVapidKey.trim().isEmpty) {
        debugPrint('Atlas Academy Web Push is waiting for its Firebase VAPID public key.');
        return false;
      }
      final token = await messaging.getToken(vapidKey: _webVapidKey.trim());
      if (token == null || token.isEmpty) throw Exception('The browser did not provide a push registration token.');
      await _save(uid, token, platform: 'web');
      _attachMessageListeners(messaging, onNotificationTap);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Atlas Academy Web Push registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (requestPermission) rethrow;
      return false;
    }
  }

  void _attachMessageListeners(
    FirebaseMessaging messaging,
    Future<void> Function(RemoteMessage message)? onNotificationTap,
  ) {
    _notificationTapHandler = onNotificationTap;
    _refresh ??= messaging.onTokenRefresh.listen((value) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _save(uid, value, platform: kIsWeb ? 'web' : null);
    });
    _foreground ??= FirebaseMessaging.onMessage.listen((message) async {
      try {
        await _showForegroundNotification(message);
      } catch (error) {
        debugPrint('Unable to display foreground push notification: $error');
      }
    });
    _opened ??= FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _recordOpen(message);
      _notificationTapHandler?.call(message);
    });
    messaging.getInitialMessage().then((initialMessage) async {
      if (initialMessage != null) {
        await _recordOpen(initialMessage);
        await _notificationTapHandler?.call(initialMessage);
      }
    });
  }

  Future<void> _save(String uid, String token, {String? platform}) async {
    var isAdmin = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        isAdmin = (await user.getIdTokenResult(true)).claims?['admin'] == true;
      }
    } catch (_) {}
    await FirebaseFirestore.instance
        .collection('user_device_tokens')
        .doc(token)
        .set({
      'userId': uid,
      'token': token,
      'isAdmin': isAdmin,
      'platform': platform ?? (kIsWeb ? 'web' : defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
      'updatedAt': FieldValue.serverTimestamp(),
      'active': true,
    }, SetOptions(merge: true));
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken(vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null);
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
    await _opened?.cancel();
    _opened = null;
  }
}


/// A user-gesture notification opt-in for web and iOS Home Screen installs.
class WebPushSetupBanner extends StatefulWidget {
  const WebPushSetupBanner({super.key});

  @override
  State<WebPushSetupBanner> createState() => _WebPushSetupBannerState();
}

class _WebPushSetupBannerState extends State<WebPushSetupBanner> {
  bool _busy = false;
  bool _enabled = false;

  Future<void> _enable() async {
    if (_busy || _enabled) return;
    setState(() => _busy = true);
    try {
      final enabled = await PushNotificationService().enableWebNotifications(context);
      if (!mounted) return;
      setState(() => _enabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(enabled
            ? 'Notifications are enabled on this device.'
            : 'Permission was not granted. On iPhone, open The Atlas Academy from its Home Screen icon on iOS 16.4 or later, then allow notifications.'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E5FA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: Color(0xFF174B80), size: 27),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay updated',
                    style: TextStyle(fontWeight: FontWeight.w800,
                        color: Color(0xFF123B68))),
                SizedBox(height: 3),
                Text('Receive membership and new-message alerts.',
                    style: TextStyle(fontSize: 11,
                        color: Color(0xFF45627F))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy || _enabled ? null : _enable,
            child: Text(_busy ? 'Please wait' : _enabled ? 'Enabled' : 'Enable'),
          ),
        ],
      ),
    );
  }
}
