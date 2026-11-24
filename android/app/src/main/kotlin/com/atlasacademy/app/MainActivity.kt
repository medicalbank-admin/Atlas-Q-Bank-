package com.atlasacademy.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.content.pm.PackageInfo
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val updateChannel = "com.atlasacademy.app/updater"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updateChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "inspectApk") {
                    try {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null || bytes.isEmpty() || bytes.size > 90 * 1024 * 1024) {
                            result.error("INVALID_APK", "The selected APK data is missing or too large.", null)
                            return@setMethodCallHandler
                        }
                        val apk = File(cacheDir, "atlas-release-inspection.apk")
                        apk.writeBytes(bytes)
                        val info = packageManager.getPackageArchiveInfo(apk.absolutePath, 0)
                        apk.delete()
                        if (info == null) {
                            result.error("INVALID_APK", "Android could not read this APK's package information.", null)
                            return@setMethodCallHandler
                        }
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        result.success(mapOf(
                            "packageName" to info.packageName,
                            "versionName" to (info.versionName ?: ""),
                            "versionCode" to versionCode.toString()
                        ))
                    } catch (error: Exception) {
                        result.error("APK_INSPECTION_FAILED", error.message ?: "Unable to inspect the selected APK.", null)
                    }
                    return@setMethodCallHandler
                }
                if (call.method != "installApk") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("INVALID_PATH", "The update file path is missing.", null)
                    return@setMethodCallHandler
                }
                try {
                    val apk = File(path)
                    if (!apk.exists() || !apk.isFile || apk.length() <= 0L) {
                        result.error("APK_MISSING", "The downloaded update file is unavailable.", null)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        !packageManager.canRequestPackageInstalls()) {
                        val settings = Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(settings)
                        result.success("permission_required")
                        return@setMethodCallHandler
                    }
                    val apkUri = FileProvider.getUriForFile(
                        this, "$packageName.fileprovider", apk
                    )
                    val installIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(apkUri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(installIntent)
                    result.success("installer_opened")
                } catch (error: Exception) {
                    result.error("INSTALL_FAILED", error.message ?: "Unable to open Android installer.", null)
                }
            }
    }
}
