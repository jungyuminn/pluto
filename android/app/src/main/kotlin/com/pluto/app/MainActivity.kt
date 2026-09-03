package com.pluto.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var deviceCalendar: DeviceCalendarPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceCalendar = DeviceCalendarPlugin.register(this, flutterEngine)
        BackupStorePlugin.register(this, flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        deviceCalendar?.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
