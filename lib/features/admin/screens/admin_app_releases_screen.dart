import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/atlas_academy_app.dart';

class AdminAppReleasesScreen extends StatefulWidget {
  const AdminAppReleasesScreen({super.key});

  @override
  State<AdminAppReleasesScreen> createState() => _AdminAppReleasesScreenState();
}

class _AdminAppReleasesScreenState extends State<AdminAppReleasesScreen> {
  final _version = TextEditingController();
  final _notes = TextEditingController();
  Uint8List? _bytes;
  String? _fileName;
  String? _apkVersion;
  String? _apkVersionCode;
  static const _apkInspector = MethodChannel('com.atlasacademy.app/updater');
  bool _busy = false;
  bool _mandatoryUpdate = false;
  double _progress = 0;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _version.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickApk() async {
    setState(() { _error = null; _success = null; });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['apk'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (!file.name.toLowerCase().endsWith('.apk') || file.bytes == null) {
        setState(() => _error = 'The selected APK could not be read. Please choose it again.');
        return;
      }
      if (file.size > 90 * 1024 * 1024) {
        setState(() => _error = 'The APK exceeds the 90 MB upload limit.');
        return;
      }
      setState(() { _bytes = file.bytes; _fileName = file.name; _apkVersion = null; _apkVersionCode = null; _version.clear(); });
      try {
        final details = await _apkInspector.invokeMapMethod<String, dynamic>(
          'inspectApk', {'bytes': file.bytes},
        );
        final actualVersion = details?['versionName']?.toString() ?? '';
        final packageName = details?['packageName']?.toString() ?? '';
        final code = details?['versionCode']?.toString() ?? '';
        if (packageName != 'com.atlasacademy.app' || actualVersion.isEmpty) {
          throw StateError('This APK is not a valid The Atlas Academy app build.');
        }
        if (!mounted) return;
        setState(() {
          _apkVersion = actualVersion;
          _apkVersionCode = code;
          _version.text = actualVersion;
        });
      } on PlatformException catch (e) {
        if (!mounted) return;
        setState(() => _error = 'Could not read the APK version automatically: ${e.message ?? e.code}. Please use the Android Admin app to inspect this APK.');
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } catch (e) {
      setState(() => _error = 'Could not select the APK: ' + e.toString());
    }
  }

  Stream<List<int>> _apkUploadChunks(Uint8List bytes) async* {
    const chunkSize = 64 * 1024;
    var sent = 0;
    var lastPercent = -1;
    while (sent < bytes.length) {
      final end = (sent + chunkSize < bytes.length)
          ? sent + chunkSize : bytes.length;
      yield Uint8List.sublistView(bytes, sent, end);
      sent = end;
      final percent = (sent * 100 / bytes.length).floor();
      if (mounted && percent != lastPercent) {
        lastPercent = percent;
        setState(() => _progress = 0.05 + 0.80 * sent / bytes.length);
      }
    }
  }

  Future<http.Response> _sendApkUpload(
      Uri uri, String token, Uint8List bytes) async {
    final client = http.Client();
    try {
      final request = http.StreamedRequest('POST', uri)
        ..headers.addAll({
          'Authorization': 'Bearer ' + token,
          'Content-Type': 'application/vnd.android.package-archive',
        })
        ..contentLength = bytes.length;
      final responseFuture = client.send(request);
      await request.sink.addStream(_apkUploadChunks(bytes));
      await request.sink.close();
      final streamed = await responseFuture.timeout(
        const Duration(minutes: 8),
      );
      final body = await streamed.stream.bytesToString();
      if (mounted) setState(() => _progress = 0.95);
      return http.Response(
        body, streamed.statusCode,
        headers: streamed.headers,
        request: streamed.request,
      );
    } finally {
      client.close();
    }
  }

  Future<void> _publish() async {
    final version = _version.text.trim();
    final bytes = _bytes;
    if (!RegExp(r'^\d+\.\d+\.\d+(?:\+\d+)?$').hasMatch(version)) {
      setState(() => _error = 'Enter a version such as 1.2.0 or 1.2.0+15.');
      return;
    }
    if (bytes == null || _fileName == null) {
      setState(() => _error = 'Choose the signed Android APK before publishing.');
      return;
    }
    if (_apkVersion == null || version != _apkVersion) {
      setState(() => _error = 'The release version must match the selected APK version. Select the APK again to read its embedded version.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Please sign in again before publishing.');
      return;
    }
    setState(() { _busy = true; _progress = 0; _error = null; _success = null; });
    try {
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        throw StateError('Your administrator sign-in could not be verified.');
      }
      final uri = Uri.parse(
        'https://atlas-academy-mcq-api.medicalbankadmin.workers.dev/releases/upload',
      ).replace(queryParameters: {
          'version': version,
          'notes': _notes.text.trim(),
          'mandatory': _mandatoryUpdate.toString(),
        });
      http.Response? result;
      for (var attempt = 1; attempt <= 3; attempt++) {
        result = await _sendApkUpload(uri, token, bytes);
        final retryable = const [500, 502, 503, 504].contains(result.statusCode);
        if (!retryable || attempt == 3) break;
        if (!mounted) return;
        setState(() {
          _progress = 0;
          _error = 'GitHub is temporarily unavailable. Retrying upload '
              '${attempt + 1} of 3…';
        });
        await Future.delayed(Duration(seconds: attempt * 2));
      }
      if (result == null) {
        throw StateError('The APK upload did not return a server response.');
      }
      Map<String, dynamic> payload = {};
      try {
        final decoded = jsonDecode(result.body);
        if (decoded is Map<String, dynamic>) payload = decoded;
      } catch (_) {}
      if (result.statusCode < 200 || result.statusCode >= 300 ||
          payload['success'] != true) {
        throw StateError(payload['message']?.toString() ??
            'The release server rejected the upload (HTTP ' +
            result.statusCode.toString() + ').');
      }
      if (!mounted) return;
      setState(() {
        _progress = 1;\n        _success = 'Version ' + version +
            ' is now published on the official Atlas Academy portal.';
        _bytes = null;
        _fileName = null;
        _apkVersion = null;
        _apkVersionCode = null;
        _version.clear();
        _notes.clear();
        _mandatoryUpdate = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Publishing failed: ' + e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      appBar: AppBar(
        title: const Text('App Release Manager'),
        backgroundColor: const Color(0xFFF2F7FF),
        foregroundColor: AtlasColors.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B1F3A), Color(0xFF174477)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFFE2C58B), size: 30),
                SizedBox(height: 14),
                Text('THE ATLAS ACADEMY', style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
                SizedBox(height: 7),
                Text('Official App Release Manager', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('Publish a new signed Android APK. The public Atlas Academy portal automatically displays the latest release.',
                  style: TextStyle(color: Color(0xFFD4E1EF), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('app_releases').doc('android').snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              return _panel('Currently published Android release',
                data == null ? const Text('No Android APK has been published yet.') :
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Version ' + (data['version']?.toString() ?? '—'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AtlasColors.navy)),
                  const SizedBox(height: 5),
                  Text(data['fileName']?.toString() ?? 'APK file',
                    style: const TextStyle(color: AtlasColors.secondaryText)),
                  if (data['fileSizeBytes'] is num)
                    Text(((data['fileSizeBytes'] as num) / 1048576).toStringAsFixed(1) + ' MB',
                      style: const TextStyle(color: AtlasColors.secondaryText)),
                  const SizedBox(height: 8),
                  const Text('Publishing another version makes it the latest download. Previous version files remain stored.',
                    style: TextStyle(fontSize: 12, height: 1.5)),
                ]));
            },
          ),
          const SizedBox(height: 18),
          _panel('Release history', StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('app_release_history')
                .orderBy('publishedAt', descending: true).limit(8).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('Published versions will appear here.',
                    style: TextStyle(color: AtlasColors.secondaryText, fontSize: 12));
              }
              return Column(children: docs.map((doc) {
                final data = doc.data();
                final size = data['fileSizeBytes'] is num
                    ? ((data['fileSizeBytes'] as num) / 1048576).toStringAsFixed(1) + ' MB'
                    : 'APK';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F2FC),
                    child: Icon(Icons.android_rounded, color: AtlasColors.royalBlue),
                  ),
                  title: Text('Version ' + (data['version']?.toString() ?? doc.id),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  subtitle: Text(size + ' · ' + (data['releaseNotes']?.toString() ?? ''),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.verified_rounded,
                      color: AtlasColors.success, size: 18),
                );
              }).toList());
            },
          )),
          const SizedBox(height: 18),
          _panel('Publish a new Android APK', Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Upload only an APK signed with the same persistent Atlas Academy release key used for previous versions. Files are stored as release assets and served through the official Atlas Academy download address. Students do not need to visit GitHub.',
                style: TextStyle(color: AtlasColors.secondaryText, height: 1.5, fontSize: 12)),
              const SizedBox(height: 15),
              TextField(controller: _version, readOnly: true, enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Actual APK version (read automatically)',
                  hintText: 'Select an APK to detect its version', border: OutlineInputBorder(),
                  helperText: 'The version is extracted from the APK itself; it cannot be typed manually.')),
              if (_apkVersion != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEAF6EE), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.verified_rounded, color: AtlasColors.success),
                    const SizedBox(width: 9),
                    Expanded(child: Text('Verified APK version: $_apkVersion · Android build code: $_apkVersionCode',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AtlasColors.success))),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _mandatoryUpdate,
                onChanged: _busy ? null : (value) => setState(() => _mandatoryUpdate = value),
                title: const Text('Mandatory update', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Students must install this version before continuing.', style: TextStyle(fontSize: 11)),
                activeColor: AtlasColors.navy,
              ),
              TextField(controller: _notes, enabled: !_busy, minLines: 2, maxLines: 4,
                decoration: const InputDecoration(labelText: 'Release notes (optional)',
                  hintText: 'Bug fixes, improvements and new features…',
                  border: OutlineInputBorder())),
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: _busy ? null : _pickApk,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(_fileName ?? 'Choose signed APK file')),
              if (_bytes != null) ...[
                const SizedBox(height: 8),
                Text('Selected: ' + (_fileName ?? 'APK') + ' · ' +
                  (_bytes!.length / 1048576).toStringAsFixed(1) + ' MB',
                  style: const TextStyle(fontSize: 11, color: AtlasColors.success)),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress == 0 ? null : _progress),
                const SizedBox(height: 7),
                Text('Uploading and publishing… ' + (_progress * 100).round().toString() + '%',
                  textAlign: TextAlign.center),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AtlasColors.error, fontSize: 12)),
              ],
              if (_success != null) ...[
                const SizedBox(height: 12),
                Text(_success!, style: const TextStyle(color: AtlasColors.success, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: _busy ? null : _publish,
                icon: const Icon(Icons.publish_rounded),
                label: Text(_busy ? 'Publishing…' : 'Publish latest release'),
                style: FilledButton.styleFrom(backgroundColor: AtlasColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 15))),
            ],
          )),
          const SizedBox(height: 18),
          _panel('Release checklist', const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckLine('APK is a release build, not a debug build.'),
              _CheckLine('Package ID remains com.atlasacademy.app.'),
              _CheckLine('APK uses the original persistent signing key.'),
              _CheckLine('Version number is higher than the installed version.'),
              _CheckLine('Test the APK on a device before announcing it.'),
            ],
          )),
          const SizedBox(height: 18),
          _panel('iPhone and desktop access', const Text(
            'The iPhone and desktop buttons on the portal open the live Atlas Academy Web App. Web updates are published through Firebase Hosting. No IPA upload is needed for the current iPhone Home Screen experience.',
            style: TextStyle(color: AtlasColors.secondaryText, height: 1.6, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE0EAF5))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
        color: AtlasColors.navy)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _CheckLine extends StatelessWidget {
  final String text;
  const _CheckLine(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.check_circle_rounded, color: AtlasColors.success, size: 17),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4,
        color: AtlasColors.charcoal))),
    ]),
  );
}
