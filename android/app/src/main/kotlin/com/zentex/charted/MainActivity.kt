package com.zentex.charted

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.Display
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val channelName = "com.zentex.charted/files"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        optimizeForHighestRefreshRate()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName") ?: "charted.pdf"
                if (bytes == null) {
                    result.error("INVALID_ARGS", "Bytes cannot be null", null)
                    return@setMethodCallHandler
                }

                try {
                    val savedPath = saveBytesToDownloads(bytes, fileName)
                    result.success(savedPath)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, null)
                }
                return@setMethodCallHandler
            }

            val filePath = call.argument<String>("path")
            if (filePath == null) {
                result.error("INVALID_PATH", "File path cannot be null", null)
                return@setMethodCallHandler
            }

            val cleanPath = if (filePath.startsWith("file://")) {
                try {
                    android.net.Uri.parse(filePath).path ?: filePath.removePrefix("file://")
                } catch (_: Exception) {
                    filePath.removePrefix("file://")
                }
            } else {
                filePath
            }

            val file = File(cleanPath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist at $cleanPath", null)
                return@setMethodCallHandler
            }

            val sharedFile = File(cacheDir, file.name)
            try {
                file.copyTo(sharedFile, overwrite = true)
            } catch (e: Exception) {
                result.error("COPY_FAILED", e.message, null)
                return@setMethodCallHandler
            }

            try {
                val uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    sharedFile
                )

                when (call.method) {
                    "openFile" -> {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/pdf")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    "shareFile" -> {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "application/pdf"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val chooser = Intent.createChooser(intent, "Share PDF").apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        try {
                            startActivity(chooser)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SHARE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("PROVIDER_ERROR", e.message, null)
            }
        }
    }

    private fun saveBytesToDownloads(bytes: ByteArray, fileName: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + File.separator + "Charted")
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(bytes)
                }
                return uri.toString()
            }
        } else {
            val downloadDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Charted")
            if (!downloadDir.exists()) {
                downloadDir.mkdirs()
            }
            val file = File(downloadDir, fileName)
            file.writeBytes(bytes)
            return file.absolutePath
        }
        throw IOException("Failed to save file to Downloads")
    }

    private fun optimizeForHighestRefreshRate() {
        val display: Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        }

        display?.let { d ->
            val supportedModes = d.supportedModes
            val maxRefreshRate = supportedModes.maxOfOrNull { it.refreshRate } ?: d.refreshRate
            val bestMode = supportedModes.maxByOrNull { it.refreshRate }

            val params = window.attributes
            params.preferredRefreshRate = maxRefreshRate

            bestMode?.let {
                params.preferredDisplayModeId = it.modeId
            }

            window.attributes = params
        }
    }
}
