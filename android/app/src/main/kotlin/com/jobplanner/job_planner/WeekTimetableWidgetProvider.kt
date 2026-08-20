package com.jobplanner.job_planner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class WeekTimetableWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            WidgetMidnightScheduler.schedule(context)
            val dark = widgetData.getBoolean("is_dark", false)
            val mutedColor = Color.parseColor("#94A3B8")
            val empty = widgetData.getString("week_timetable_empty", "이번 주 일정이 없어요")
                ?: "이번 주 일정이 없어요"
            val path = widgetData.getString("week_timetable_image", null)
            val bitmap = path?.takeIf { File(it).exists() }?.let { decodeBitmap(context, it) }

            val views = RemoteViews(context.packageName, R.layout.week_timetable_widget).apply {
                setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    if (dark) R.drawable.widget_card_dark else R.drawable.widget_card_light,
                )
                setTextViewText(R.id.widget_empty, empty)
                setTextColor(R.id.widget_empty, mutedColor)

                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_grid, bitmap)
                    setViewVisibility(R.id.widget_grid, View.VISIBLE)
                    setViewVisibility(R.id.widget_empty, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_grid, View.GONE)
                    setViewVisibility(R.id.widget_empty, View.VISIBLE)
                }

                val openApp = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                }
                val openAppPending = PendingIntent.getActivity(
                    context,
                    widgetId,
                    openApp,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                setOnClickPendingIntent(R.id.widget_root, openAppPending)
                setOnClickPendingIntent(R.id.widget_grid, openAppPending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            HomeWidgetPlugin.getData(context),
        )
    }

    private fun decodeBitmap(context: Context, path: String): android.graphics.Bitmap? {
        val density = context.resources.displayMetrics.densityDpi
        val options = BitmapFactory.Options().apply {
            inScaled = true
            inDensity = density
            inTargetDensity = density
            inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(path, options)
    }
}
