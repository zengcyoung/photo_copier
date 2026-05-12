package com.ewanyang.photo_copier

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.ewanyang.photo_copier/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStorageVolumes" -> {
                        try {
                            result.success(getStorageVolumes())
                        } catch (e: Exception) {
                            result.error("STORAGE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getStorageVolumes(): List<Map<String, Any>> {
        val volumes = mutableListOf<Map<String, Any>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val sm = getSystemService(Context.STORAGE_SERVICE) as StorageManager
            for (vol in sm.storageVolumes) {
                val path = getVolumePath(vol) ?: continue
                val file = File(path)
                if (!file.exists() || !file.canRead()) continue
                volumes.add(
                    mapOf(
                        "path" to path,
                        "name" to (vol.getDescription(this) ?: if (vol.isPrimary) "Internal Storage" else "External Storage"),
                        "isRemovable" to vol.isRemovable,
                        "isPrimary" to vol.isPrimary,
                    )
                )
            }
        }

        // Fallback: always include internal storage
        if (volumes.isEmpty()) {
            val internalPath = Environment.getExternalStorageDirectory().absolutePath
            volumes.add(
                mapOf(
                    "path" to internalPath,
                    "name" to "Internal Storage",
                    "isRemovable" to false,
                    "isPrimary" to true,
                )
            )
        }

        return volumes
    }

    @Suppress("DEPRECATION")
    private fun getVolumePath(volume: StorageVolume): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            volume.directory?.absolutePath
        } else {
            // Reflection fallback for API 24-29
            try {
                val method = StorageVolume::class.java.getMethod("getPath")
                method.invoke(volume) as? String
            } catch (e: Exception) {
                null
            }
        }
    }
}
