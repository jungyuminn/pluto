package com.pluto.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class DeviceCalendarPlugin(
    private val activity: Activity,
) : MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        const val channelName = "job_planner/device_calendar"
        private const val permissionRequest = 2401
        private const val maxEvents = 3000

        fun register(activity: Activity, engine: FlutterEngine): DeviceCalendarPlugin {
            val plugin = DeviceCalendarPlugin(activity)
            MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
                .setMethodCallHandler(plugin)
            return plugin
        }
    }

    private var permissionResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestPermission" -> requestPermission(result)
            "openSettings" -> {
                openSettings()
                result.success(null)
            }
            "listCalendars" -> {
                if (!hasPermission()) {
                    result.error("permission", "READ_CALENDAR", null)
                    return
                }
                result.success(listCalendars())
            }
            "listEvents" -> {
                if (!hasPermission()) {
                    result.error("permission", "READ_CALENDAR", null)
                    return
                }
                val ids = call.argument<List<Any>>("calendarIds")
                    ?.mapNotNull { it.toString().toLongOrNull() }
                    .orEmpty()
                val from = (call.argument<Number>("fromMillis")?.toLong()) ?: 0L
                val to = (call.argument<Number>("toMillis")?.toLong()) ?: 0L
                result.success(listEvents(ids, from, to))
            }
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != permissionRequest) return false
        val result = permissionResult ?: return true
        permissionResult = null
        result.success(permissionStatus(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED))
        return true
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success("granted")
            return
        }
        if (permissionResult != null) {
            result.error("busy", "permission", null)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.READ_CALENDAR),
            permissionRequest,
        )
    }

    private fun permissionStatus(granted: Boolean): String {
        if (granted) return "granted"
        val rationale = ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            Manifest.permission.READ_CALENDAR,
        )
        return if (rationale) "denied" else "permanentlyDenied"
    }

    private fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_CALENDAR,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun openSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", activity.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        activity.startActivity(intent)
    }

    private fun listCalendars(): List<Map<String, Any?>> {
        val counts = eventCounts()
        val items = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.OWNER_ACCOUNT,
            CalendarContract.Calendars.VISIBLE,
        )
        activity.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.VISIBLE}=1",
            null,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
            val accountIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_NAME)
            val typeIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.ACCOUNT_TYPE)
            val ownerIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.OWNER_ACCOUNT)
            while (cursor.moveToNext()) {
                val name = cursor.getString(nameIndex).orEmpty()
                val account = cursor.getString(accountIndex).orEmpty()
                val type = cursor.getString(typeIndex).orEmpty()
                val owner = cursor.getString(ownerIndex).orEmpty()
                if (isExcludedCalendar(name, "$account $owner", type)) continue
                val id = cursor.getLong(idIndex).toString()
                items.add(
                    mapOf(
                        "id" to id,
                        "name" to name.ifBlank { account.ifBlank { "캘린더" } },
                        "accountName" to account,
                        "eventCount" to (counts[id] ?: 0),
                    ),
                )
            }
        }
        return items
    }

    private fun eventCounts(): Map<String, Int> {
        val counts = mutableMapOf<String, Int>()
        val projection = arrayOf(
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.TITLE,
        )
        activity.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            "${CalendarContract.Events.DELETED}=0",
            null,
            null,
        )?.use { cursor ->
            val calendarIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE)
            while (cursor.moveToNext()) {
                val title = cursor.getString(titleIndex)?.trim().orEmpty()
                if (title.isEmpty()) continue
                val id = cursor.getLong(calendarIndex).toString()
                counts[id] = (counts[id] ?: 0) + 1
            }
        }
        return counts
    }

    private fun listEvents(
        calendarIds: List<Long>,
        fromMillis: Long,
        toMillis: Long,
    ): List<Map<String, Any?>> {
        if (calendarIds.isEmpty() || toMillis <= fromMillis) return emptyList()
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        android.content.ContentUris.appendId(builder, fromMillis)
        android.content.ContentUris.appendId(builder, toMillis)
        val placeholders = calendarIds.joinToString(",") { "?" }
        val args = calendarIds.map { it.toString() }.toTypedArray()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
        )
        val items = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(
            builder.build(),
            projection,
            "${CalendarContract.Instances.CALENDAR_ID} IN ($placeholders)",
            args,
            "${CalendarContract.Instances.BEGIN} ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
            val calendarIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)
            val notesIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION)
            val beginIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
            val endIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.END)
            val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)
            while (cursor.moveToNext()) {
                val title = cursor.getString(titleIndex)?.trim().orEmpty()
                if (title.isEmpty()) continue
                items.add(
                    mapOf(
                        "eventId" to cursor.getLong(idIndex).toString(),
                        "calendarId" to cursor.getLong(calendarIndex).toString(),
                        "title" to title,
                        "notes" to cursor.getString(notesIndex).orEmpty(),
                        "startMillis" to cursor.getLong(beginIndex),
                        "endMillis" to cursor.getLong(endIndex),
                        "allDay" to (cursor.getInt(allDayIndex) == 1),
                    ),
                )
                if (items.size >= maxEvents) break
            }
        }
        return items
    }

    private fun isExcludedCalendar(name: String, account: String, type: String): Boolean {
        val hay = "$name $account $type".lowercase()
        return listOf(
            "holiday",
            "holidays",
            "공휴일",
            "국경일",
            "휴일",
            "절기",
            "명절",
            "birthday",
            "birthdays",
            "생일",
            "생신",
            "anniversary",
            "기념일",
            "contacts",
            "연락처",
            "주소록",
        ).any(hay::contains)
    }
}
