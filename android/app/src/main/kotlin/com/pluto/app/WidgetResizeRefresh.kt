package com.pluto.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.max

object WidgetResizeRefresh {
    private val handler = Handler(Looper.getMainLooper())
    private var pending: Runnable? = null

    fun saveMonthSizes(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        val edit = HomeWidgetPlugin.getData(context).edit()
        edit.putString("month_widget_ids", widgetIds.joinToString(","))
        widgetIds.forEach { id ->
            val options = manager.getAppWidgetOptions(id)
            edit.putInt("month_widget_${id}_w", sizeDp(options, width = true))
            edit.putInt("month_widget_${id}_h", sizeDp(options, width = false))
        }
        edit.apply()
    }

    fun removeMonthSizes(context: Context, widgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val gone = widgetIds.toSet()
        val remaining = (prefs.getString("month_widget_ids", "") ?: "")
            .split(',')
            .mapNotNull { it.trim().toIntOrNull() }
            .filter { it !in gone }
        val edit = prefs.edit().putString("month_widget_ids", remaining.joinToString(","))
        widgetIds.forEach { id ->
            edit.remove("month_widget_${id}_w")
            edit.remove("month_widget_${id}_h")
        }
        edit.apply()
    }

    fun schedule(context: Context) {
        val app = context.applicationContext
        pending?.let(handler::removeCallbacks)
        val next = Runnable {
            val intent = Intent(app, HomeWidgetBackgroundReceiver::class.java).apply {
                action = "es.antonborri.home_widget.action.BACKGROUND"
                data = Uri.parse("jobplanner://refresh")
            }
            app.sendBroadcast(intent)
        }
        pending = next
        handler.postDelayed(next, 400)
    }

    private fun sizeDp(options: android.os.Bundle, width: Boolean): Int {
        val minKey = if (width) {
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
        } else {
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT
        }
        val maxKey = if (width) {
            AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH
        } else {
            AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
        }
        return max(options.getInt(minKey, 0), options.getInt(maxKey, 0))
            .coerceAtLeast(180)
            .coerceAtMost(900)
    }
}
