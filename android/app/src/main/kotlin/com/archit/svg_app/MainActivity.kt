package com.archit.pix_glance

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app.channel.shared.data"
    private var sharedData: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedData") {
                result.success(sharedData)
                sharedData = null // Clear after retrieving
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    sharedData = getFilePathFromUri(uri)
                }
            }
            Intent.ACTION_SEND -> {
                if (intent.type?.startsWith("image/") == true) {
                    intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uri ->
                        sharedData = getFilePathFromUri(uri)
                    }
                }
            }
        }
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> {
                // Handle content URIs by copying to app directory
                try {
                    val inputStream = contentResolver.openInputStream(uri)
                    val fileName = getFileName(uri)
                    val tempFile = File(cacheDir, fileName)

                    inputStream?.use { input ->
                        tempFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }

                    tempFile.absolutePath
                } catch (e: Exception) {
                    e.printStackTrace()
                    null
                }
            }
            else -> null
        }
    }

    private fun getFileName(uri: Uri): String {
        var fileName = "temp_image"

        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) {
                    fileName = cursor.getString(nameIndex) ?: "temp_image"
                }
            }
        }

        return fileName
    }
}