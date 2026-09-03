package com.pluto.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import java.util.Calendar

class WidgetMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        WidgetMidnightScheduler.schedule(context)
        val refresh = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            action = "es.antonborri.home_widget.action.BACKGROUND"
            data = Uri.parse("jobplanner://refresh")
        }
        context.sendBroadcast(refresh)
    }
}

object WidgetMidnightScheduler {
    private const val REQUEST = 71001
    const val ACTION = "com.pluto.app.WIDGET_MIDNIGHT"

    fun schedule(context: Context) {
        val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetMidnightReceiver::class.java).setAction(ACTION)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val triggerAt = nextMidnight()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarm.canScheduleExactAlarms()) {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
                return
            }
            alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        } catch (_: SecurityException) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        }
    }

    private fun nextMidnight(): Long {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 8)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}
