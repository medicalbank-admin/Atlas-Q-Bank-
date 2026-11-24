import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/atlas_academy_app.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});
  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> with WidgetsBindingObserver {
  static const _api = 'https://atlas-academy-mcq-api.medicalbankadmin.workers.dev';
  static const _installer = MethodChannel('com.atlasacademy.app/updater');
  Map<String, dynamic>? _release;
  bool _promptOpen = false;
  bool _checking = false;
  bool _mandatory = false;
  bool _downloading = false;
  double _progress = 0;
  String? _pendingApkPath;
  bool _waitingForInstallPermission = false;
  bool _installerWasOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_waitingForInstallPermission && _pendingApkPath != null) {
        _waitingForInstallPermission = false;
        _installDownloadedApk();
      } else if (_installerWasOpened && !_checking) {
        _installerWasOpened = false;
        _release = null;
        _checkForUpdate();
      } else if (!_promptOpen && !_checking && _release == null) {
        _checkForUpdate();
      }
    }
  }

  int _compareVersions(String a, String b) {
    List<int> parts(String value) {
      final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$').firstMatch(value);
      if (match == null) return [0, 0, 0, 0];
      return [for (var i = 1; i <= 4; i++) int.tryParse(match.group(i) ?? '0') ?? 0];
    }
    final left = parts(a);
    final right = parts(b);
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return left[i].compareTo(right[i]);
    }
    return 0;
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid || _checking || !mounted) return;
    _checking = true;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      try {
        final request = await client.getUrl(Uri.parse('$_api/releases/latest'));
        final response = await request.close().timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) return;
        final body = await response.transform(utf8.decoder).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        if (payload['success'] != true || payload['release'] is! Map) return;
        final release = Map<String, dynamic>.from(payload['release'] as Map);
        final info = await PackageInfo.fromPlatform();
        final latest = (release['version'] ?? '').toString();
        final installed = info.version + (info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : '');
        if (_compareVersions(latest, installed) <= 0) return;
        final url = Uri.tryParse((release['downloadUrl'] ?? '').toString());
        if (url == null || url.host != Uri.parse(_api).host ||
            url.path != '/releases/download') return;
        if (!mounted) return;
        setState(() {
          _release = release;
          _mandatory = release['isMandatory'] == true;
        });
        _showUpdateDialog();
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      // Update checks are best-effort. Never block normal app use on network failure.
    } finally {
      _checking = false;
    }
  }

  Future<void> _showUpdateDialog() async {
    if (!mounted || _promptOpen || _release == null) return;
    _promptOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: !_mandatory,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) {
          final release = _release!;
          final notes = (release['releaseNotes'] ?? '').toString().trim();
          return PopScope(
            canPop: !_mandatory && !_downloading,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(children: [
                const Icon(Icons.system_update_alt_rounded, color: AtlasColors.royalBlue, size: 27),
                const SizedBox(width: 10),
                const Expanded(child: Text('Update available', style: TextStyle(fontWeight: FontWeight.w900))),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('A new version of The Atlas Academy is ready.', style: TextStyle(height: 1.45)),
                const SizedBox(height: 10),
                Text('Version ${release['version'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, color: AtlasColors.navy)),
                if (_mandatory) ...[
                  const SizedBox(height: 8),
                  const Text('This update is required to continue using the app.', style: TextStyle(color: AtlasColors.warning, fontWeight: FontWeight.w700)),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('What’s new', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(notes, style: const TextStyle(fontSize: 13, height: 1.45)),
                ],
                if (_downloading) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                  const SizedBox(height: 7),
                  Text('Downloading update… ${(_progress * 100).round()}%', style: const TextStyle(fontSize: 12)),
                ],
              ]),
              actions: [
                if (!_mandatory && !_downloading)
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Later')),
                FilledButton.icon(
                  onPressed: _downloading ? null : () async {
                    refreshDialog(() => _downloading = true);
                    await _downloadAndInstall((value) {
                      if (mounted) refreshDialog(() => _progress = value);
                    });
                    if (mounted && _promptOpen) refreshDialog(() => _downloading = false);
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(_downloading ? 'Downloading…' : 'Update Now'),
                ),
              ],
            ),
          );
        },
      ),
    );
    _promptOpen = false;
    if (mounted && _mandatory && _pendingApkPath == null) {
      // Recheck if the mandatory dialog was closed by a platform interruption.
      Future<void>.delayed(const Duration(seconds: 2), _showUpdateDialog);
    }
  }

  Future<void> _downloadAndInstall(void Function(double) onProgress) async {
    try {
      final release = _release;
      if (release == null) return;
      final url = Uri.parse(release['downloadUrl'].toString());
      final expected = int.tryParse(release['fileSizeBytes'].toString()) ?? 0;
      if (expected <= 0 || expected > 90 * 1024 * 1024) {
        throw Exception('The published APK size is invalid. Please contact the academy.');
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/atlas-academy-update.apk');
      if (await file.exists()) await file.delete();
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      try {
        final request = await client.getUrl(url);
        final response = await request.close().timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          throw Exception('The official update server returned HTTP ${response.statusCode}.');
        }
        final sink = file.openWrite();
        var received = 0;
        try {
          await for (final chunk in response) {
            received += chunk.length;
            if (received > expected || received > 90 * 1024 * 1024) {
              throw Exception('The downloaded file size did not match the published APK.');
            }
            sink.add(chunk);
            onProgress(received / expected);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (received != expected || received == 0) {
          throw Exception('The APK download was incomplete. Please try again.');
        }
      } finally {
        client.close(force: true);
      }
      _pendingApkPath = file.path;
      await _installDownloadedApk();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update could not be completed: $error'),
        action: SnackBarAction(label: 'Retry', onPressed: _showUpdateDialog),
      ));
    }
  }

  Future<void> _installDownloadedApk() async {
    final path = _pendingApkPath;
    if (path == null || !mounted) return;
    try {
      final result = await _installer.invokeMethod<String>('installApk', {'path': path});
      if (result == 'permission_required') {
        _waitingForInstallPermission = true;
        if (_promptOpen && Navigator.of(context).canPop()) {
          _promptOpen = false;
          Navigator.of(context).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('Allow The Atlas Academy to install updates on the next screen, then return here.'),
          ));
        }
      } else if (result == 'installer_opened') {
        _installerWasOpened = true;
        if (_promptOpen && Navigator.of(context).canPop()) {
          _promptOpen = false;
          Navigator.of(context).pop();
        }
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.message ?? 'Android could not open the installer.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
