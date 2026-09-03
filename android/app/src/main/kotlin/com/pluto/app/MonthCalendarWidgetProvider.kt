package com.pluto.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class MonthCalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                WidgetMidnightScheduler.schedule(context)
                val dark = widgetData.getBoolean("is_dark", false)
                val mutedColor = Color.parseColor("#94A3B8")
                val empty = widgetData.getString("month_calendar_empty", "이번 달 일정이 없어요")
                    ?: "이번 달 일정이 없어요"
                val path = widgetData.getString("month_calendar_image", null)
                val bitmap = WidgetSkin.decodeUnscaled(path)
                    ?: WidgetSkin.decode(context, path)

                val views = RemoteViews(context.packageName, R.layout.month_calendar_widget).apply {
                    WidgetSkin.apply(
                        context,
                        this,
                        widgetData,
                        dark,
                        R.id.widget_root,
                        R.id.widget_skin_bg,
                        showImage = bitmap == null,
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
                        widgetId + 3000,
                        openApp,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    setOnClickPendingIntent(R.id.widget_root, openAppPending)
                    setOnClickPendingIntent(R.id.widget_grid, openAppPending)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (error: Exception) {
                Log.e("MonthCalendarWidget", "update failed", error)
            }
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
}
