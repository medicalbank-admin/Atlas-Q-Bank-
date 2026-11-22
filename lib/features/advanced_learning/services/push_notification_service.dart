import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Registers this installation for FCM delivery. A trusted server must send
/// FCM HTTP v1 messages; client apps must never contain service-account keys.
class PushNotificationService {
  static const String _apiUrl = String.fromEnvironment('PUSH_API_URL');
  Future<int> sendAnnouncement({required String title,required String body,String? userId}) async {
    if(_apiUrl.trim().isEmpty) throw Exception('Push service endpoint is not configured in this app build.');
    final user=FirebaseAuth.instance.currentUser;
    if(user==null) throw Exception('Administrator sign-in is required.');
    final token=await user.getIdToken();
    final response=await http.post(Uri.parse('${_apiUrl.replaceAll(RegExp(r'/+
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;
  Future<void> registerDevice() async {
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return;
    try{
      final messaging=FirebaseMessaging.instance;
      final settings=await messaging.requestPermission(alert:true,badge:true,sound:true);
      if(settings.authorizationStatus==AuthorizationStatus.denied)return;
      final token=await messaging.getToken();
      if(token!=null&&token.isNotEmpty)await _save(user.uid,token);
      _refresh??=messaging.onTokenRefresh.listen((value)=>_save(user.uid,value));
      _foreground??=FirebaseMessaging.onMessage.listen((message){});
    }catch(_){/* Push registration is optional when device permission/network is unavailable. */}
  }
  Future<void> _save(String uid,String token)async{
    await FirebaseFirestore.instance.collection('user_device_tokens').doc(token).set({
      'userId':uid,'token':token,'platform':'flutter','updatedAt':FieldValue.serverTimestamp(),'active':true,
    },SetOptions(merge:true));
  }
  Future<void> unregisterCurrentDevice()async{
    final token=await FirebaseMessaging.instance.getToken();
    if(token!=null)await FirebaseFirestore.instance.collection('user_device_tokens').doc(token).delete();
    await _refresh?.cancel();_refresh=null;await _foreground?.cancel();_foreground=null;
  }
}
), '')}/send'),headers:{'Authorization':'Bearer $token','Content-Type':'application/json'},body:jsonEncode({'title':title,'body':body,if(userId!=null)'userId':userId})).timeout(const Duration(seconds:30));
    final data=jsonDecode(response.body);
    if(response.statusCode<200||response.statusCode>=300||data is! Map||data['success']!=true)throw Exception(data is Map?(data['message']??'Push delivery failed.').toString():'Push service returned an invalid response.');
    return (data['sent'] as num?)?.toInt()??0;
  }
  StreamSubscription<String>? _refresh;
  StreamSubscription<RemoteMessage>? _foreground;
  Future<void> registerDevice() async {
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return;
    try{
      final messaging=FirebaseMessaging.instance;
      final settings=await messaging.requestPermission(alert:true,badge:true,sound:true);
      if(settings.authorizationStatus==AuthorizationStatus.denied)return;
      final token=await messaging.getToken();
      if(token!=null&&token.isNotEmpty)await _save(user.uid,token);
      _refresh??=messaging.onTokenRefresh.listen((value)=>_save(user.uid,value));
      _foreground??=FirebaseMessaging.onMessage.listen((message){});
    }catch(_){/* Push registration is optional when device permission/network is unavailable. */}
  }
  Future<void> _save(String uid,String token)async{
    await FirebaseFirestore.instance.collection('user_device_tokens').doc(token).set({
      'userId':uid,'token':token,'platform':'flutter','updatedAt':FieldValue.serverTimestamp(),'active':true,
    },SetOptions(merge:true));
  }
  Future<void> unregisterCurrentDevice()async{
    final token=await FirebaseMessaging.instance.getToken();
    if(token!=null)await FirebaseFirestore.instance.collection('user_device_tokens').doc(token).delete();
    await _refresh?.cancel();_refresh=null;await _foreground?.cancel();_foreground=null;
  }
}
