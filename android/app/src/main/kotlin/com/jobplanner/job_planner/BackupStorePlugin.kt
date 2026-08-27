package com.jobplanner.job_planner

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class BackupStorePlugin(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val channelName = "job_planner/backup_store"
        private const val mimeType = "application/zip"

        fun register(activity: Activity, engine: FlutterEngine): BackupStorePlugin {
            val plugin = BackupStorePlugin(activity)
            MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
                .setMethodCallHandler(plugin)
            return plugin
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveDownload" -> {
                val fileName = call.argument<String>("fileName")
                val bytes = argumentBytes(call)
                if (fileName.isNullOrEmpty() || bytes == null) {
                    result.error("invalid", "fileName and bytes are required", null)
                    return
                }
                try {
                    saveDownload(fileName, bytes)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("save_failed", error.message, null)
                }
            }
            "pruneDownloads" -> {
                val keep = call.argument<Int>("keep") ?: 3
                val prefix = call.argument<String>("prefix") ?: "잡플래너_백업_"
                try {
                    pruneDownloads(prefix, keep)
                    result.success(null)
                } catch (error: Exception) {
                    result.error("prune_failed", error.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun saveDownload(fileName: String, bytes: ByteArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = activity.contentResolver
            val existing = findOwned(fileName)
            val uri = existing ?: resolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    put(MediaStore.Downloads.IS_PENDING, 1)
                },
            ) ?: throw IllegalStateException("insert failed")
            resolver.openOutputStream(uri, if (existing == null) "w" else "rwt")?.use { stream ->
                stream.write(bytes)
            } ?: throw IllegalStateException("open stream failed")
            if (existing == null) {
                resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                    null,
                    null,
                )
            }
            return
        }
        val folder = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        folder.mkdirs()
        File(folder, fileName).writeBytes(bytes)
    }

    private fun pruneDownloads(prefix: String, keep: Int) {
        if (keep < 1) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = activity.contentResolver
            val items = mutableListOf<Pair<Long, Uri>>()
            resolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Downloads._ID, MediaStore.Downloads.DISPLAY_NAME, MediaStore.Downloads.DATE_ADDED),
                "${MediaStore.Downloads.DISPLAY_NAME} LIKE ?",
                arrayOf("$prefix%"),
                "${MediaStore.Downloads.DATE_ADDED} DESC",
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
                while (cursor.moveToNext()) {
                    val name = cursor.getString(nameColumn) ?: continue
                    if (!name.startsWith(prefix) || !name.endsWith(".zip", ignoreCase = true)) continue
                    val id = cursor.getLong(idColumn)
                    items += id to ContentUris.withAppendedId(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                        id,
                    )
                }
            }
            items.drop(keep).forEach { (_, uri) ->
                try {
                    resolver.delete(uri, null, null)
                } catch (_: SecurityException) {
                }
            }
            return
        }
        val folder = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!folder.exists()) return
        val files = folder.listFiles()
            ?.filter { it.isFile && it.name.startsWith(prefix) && it.name.endsWith(".zip", ignoreCase = true) }
            ?.sortedByDescending { it.lastModified() }
            ?: return
        files.drop(keep).forEach { it.delete() }
    }

    private fun argumentBytes(call: MethodCall): ByteArray? {
        return when (val raw = call.argument<Any>("bytes")) {
            is ByteArray -> raw
            is List<*> -> ByteArray(raw.size) { index ->
                (raw[index] as Number).toByte()
            }
            else -> null
        }
    }

    private fun findOwned(fileName: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val resolver = activity.contentResolver
        resolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.Downloads._ID),
            "${MediaStore.Downloads.DISPLAY_NAME}=?",
            arrayOf(fileName),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID))
                return ContentUris.withAppendedId(MediaStore.Downloads.EXTERNAL_CONTENT_URI, id)
            }
        }
        return null
    }
}
