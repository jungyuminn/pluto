package com.jobplanner.job_planner

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

abstract class CompactDayWidgetProvider : HomeWidgetProvider() {
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
            try {
                bind(context, appWidgetManager, widgetId, widgetData)
            } catch (error: Exception) {
                Log.e("CompactDayWidget", "update failed", error)
            }
        }
    }

    private fun bind(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        WidgetMidnightScheduler.schedule(context)
        val dark = boolOf(widgetData, "is_dark", false)
        val textColor = intOf(
            widgetData,
            "widget_text",
            if (dark) 0xFFF1F5F9.toInt() else 0xFF0F172A.toInt(),
        )
        val mutedColor = Color.parseColor("#94A3B8")
        val title = stringOf(widgetData, "${kind}_title", defaultTitle)
        val date = stringOf(widgetData, "${kind}_date", "")
        val empty = stringOf(widgetData, "${kind}_empty", defaultEmpty)
        val count = intOf(widgetData, "${kind}_count", 0)
        val more = intOf(widgetData, "${kind}_more", 0)

        val views = RemoteViews(context.packageName, R.layout.compact_day_widget).apply {
            WidgetSkin.apply(
                context,
                this,
                widgetData,
                dark,
                R.id.widget_root,
                R.id.widget_skin_bg,
            )
            setTextViewText(R.id.widget_day_title, title)
            setTextColor(R.id.widget_day_title, textColor)
            setTextViewText(R.id.widget_day_date, date)
            setTextColor(R.id.widget_day_date, textColor)
            setTextViewText(R.id.widget_empty, empty)
            setTextColor(R.id.widget_empty, mutedColor)
            setViewVisibility(R.id.widget_empty, if (count == 0) View.VISIBLE else View.GONE)

            for (index in 0 until rowCount) {
                val rowId = rowIds[index]
                val titleId = titleIds[index]
                val dotId = dotIds[index]
                if (index >= count) {
                    setViewVisibility(rowId, View.GONE)
                    continue
                }
                val itemTitle = stringOf(widgetData, "${kind}_item_${index}_title", "")
                val itemColor = intOf(
                    widgetData,
                    "${kind}_item_${index}_color",
                    0xFF3B82F6.toInt(),
                )
                setViewVisibility(rowId, View.VISIBLE)
                setTextViewText(titleId, itemTitle)
                setTextColor(titleId, textColor)
                setInt(dotId, "setColorFilter", itemColor)
            }

            if (more > 0 && count > 0) {
                setViewVisibility(R.id.widget_more, View.VISIBLE)
                setTextViewText(R.id.widget_more, "외 ${more}개")
                setTextColor(R.id.widget_more, mutedColor)
            } else {
                setViewVisibility(R.id.widget_more, View.GONE)
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
                widgetId + 2000,
                openApp,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, openAppPending)
        }
        appWidgetManager.updateAppWidget(widgetId, views)
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

    private fun intOf(prefs: SharedPreferences, key: String, fallback: Int): Int {
        return when (val value = prefs.all[key]) {
            is Int -> value
            is Long -> value.toInt()
            is String -> value.toIntOrNull() ?: fallback
            is Float -> value.toInt()
            is Double -> value.toInt()
            else -> fallback
        }
    }

    private fun stringOf(prefs: SharedPreferences, key: String, fallback: String): String {
        return when (val value = prefs.all[key]) {
            is String -> value
            null -> fallback
            else -> value.toString()
        }
    }

    private fun boolOf(prefs: SharedPreferences, key: String, fallback: Boolean): Boolean {
        return when (val value = prefs.all[key]) {
            is Boolean -> value
            is Int -> value != 0
            is Long -> value != 0L
            is String -> value == "true" || value == "1"
            else -> fallback
        }
    }

    companion object {
        private const val rowCount = 6
        private val rowIds = intArrayOf(
            R.id.widget_item_0,
            R.id.widget_item_1,
            R.id.widget_item_2,
            R.id.widget_item_3,
            R.id.widget_item_4,
            R.id.widget_item_5,
        )
        private val titleIds = intArrayOf(
            R.id.widget_item_0_title,
            R.id.widget_item_1_title,
            R.id.widget_item_2_title,
            R.id.widget_item_3_title,
            R.id.widget_item_4_title,
            R.id.widget_item_5_title,
        )
        private val dotIds = intArrayOf(
            R.id.widget_item_0_dot,
            R.id.widget_item_1_dot,
            R.id.widget_item_2_dot,
            R.id.widget_item_3_dot,
            R.id.widget_item_4_dot,
            R.id.widget_item_5_dot,
        )
    }
}

class CompactTodayWidgetProvider : CompactDayWidgetProvider() {
    override val kind = "today_glance"
    override val defaultTitle = "오늘"
    override val defaultEmpty = "오늘 일정이 없어요"
}

class CompactTomorrowWidgetProvider : CompactDayWidgetProvider() {
    override val kind = "tomorrow_glance"
    override val defaultTitle = "내일"
    override val defaultEmpty = "내일 일정이 없어요"
}
