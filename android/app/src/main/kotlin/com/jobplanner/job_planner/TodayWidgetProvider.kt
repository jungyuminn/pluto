package com.jobplanner.job_planner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

abstract class ScheduleWidgetProvider : HomeWidgetProvider() {
    abstract val kind: String
    abstract val defaultTitle: String
    abstract val defaultEmpty: String

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            WidgetMidnightScheduler.schedule(context)
            val dark = widgetData.getBoolean("is_dark", false)
            val textColor = if (dark) Color.parseColor("#F1F5F9") else Color.parseColor("#0F172A")
            val mutedColor = Color.parseColor("#94A3B8")
            val views = RemoteViews(context.packageName, R.layout.today_widget).apply {
                WidgetSkin.apply(
                    context,
                    this,
                    widgetData,
                    dark,
                    R.id.widget_root,
                    R.id.widget_skin_bg,
                )
                val headerPath = widgetData.getString("${kind}_header", null)
                val headerBitmap = WidgetSkin.decodeUnscaled(headerPath)
                    ?: WidgetSkin.decode(context, headerPath)
                if (headerBitmap != null) {
                    setImageViewBitmap(R.id.widget_header, headerBitmap)
                    setViewVisibility(R.id.widget_header, View.VISIBLE)
                    setViewVisibility(R.id.widget_title, View.GONE)
                    setViewVisibility(R.id.widget_date, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_header, View.GONE)
                    setViewVisibility(R.id.widget_title, View.VISIBLE)
                    setViewVisibility(R.id.widget_date, View.VISIBLE)
                    setTextViewText(
                        R.id.widget_title,
                        widgetData.getString("${kind}_title", defaultTitle) ?: defaultTitle,
                    )
                    setTextColor(R.id.widget_title, textColor)
                    setTextViewText(
                        R.id.widget_date,
                        widgetData.getString("${kind}_date", "") ?: "",
                    )
                    setTextColor(R.id.widget_date, mutedColor)
                }
                setTextViewText(
                    R.id.widget_empty,
                    widgetData.getString("${kind}_empty", defaultEmpty) ?: defaultEmpty,
                )
                setTextColor(R.id.widget_empty, mutedColor)

                val service = Intent(context, TodayWidgetViewsService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    putExtra(TodayWidgetViewsService.EXTRA_KIND, kind)
                    data = Uri.parse("jobplanner://widget/$kind/$widgetId")
                }
                setRemoteAdapter(R.id.widget_list, service)
                setEmptyView(R.id.widget_list, R.id.widget_empty)

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
                setOnClickPendingIntent(R.id.widget_header, openAppPending)
                setOnClickPendingIntent(R.id.widget_title, openAppPending)
                setOnClickPendingIntent(R.id.widget_date, openAppPending)

                val template = Intent(context, TodayWidgetClickReceiver::class.java)
                val templatePending = PendingIntent.getBroadcast(
                    context,
                    widgetId + 1000,
                    template,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                setPendingIntentTemplate(R.id.widget_list, templatePending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
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
            es.antonborri.home_widget.HomeWidgetPlugin.getData(context),
        )
    }
}

class TodayWidgetProvider : ScheduleWidgetProvider() {
    override val kind = "today"
    override val defaultTitle = "오늘"
    override val defaultEmpty = "오늘 일정이 없어요"
}

class TomorrowWidgetProvider : ScheduleWidgetProvider() {
    override val kind = "tomorrow"
    override val defaultTitle = "내일"
    override val defaultEmpty = "내일 일정이 없어요"
}

class TodayTomorrowWidgetProvider : ScheduleWidgetProvider() {
    override val kind = "today_tomorrow"
    override val defaultTitle = "오늘 + 내일"
    override val defaultEmpty = "오늘과 내일 일정이 없어요"
}
