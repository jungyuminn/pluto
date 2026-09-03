package com.pluto.app

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class TodayWidgetViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val kind = intent.getStringExtra(EXTRA_KIND) ?: "today"
        return TodayWidgetViewsFactory(applicationContext, kind)
    }

    companion object {
        const val EXTRA_KIND = "kind"
    }
}

class TodayWidgetViewsFactory(
    private val context: Context,
    private val kind: String,
) : RemoteViewsService.RemoteViewsFactory {
    private var rows = emptyList<Pair<String, String>>()

    override fun onCreate() {}

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun onDataSetChanged() {
        val prefs = HomeWidgetPlugin.getData(context)
        val count = rowCount(prefs)
        rows = (0 until count).mapNotNull { index ->
            val path = prefs.getString("${kind}_row_$index", null)?.takeIf { File(it).exists() }
                ?: return@mapNotNull null
            val id = prefs.getString("${kind}_row_${index}_id", "") ?: ""
            path to id
        }
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.today_widget_row)
        val row = rows.getOrNull(position)
        val bitmap = row?.first?.let(::decodeRowBitmap)
        if (bitmap != null) {
            views.setImageViewBitmap(R.id.widget_row_image, bitmap)
        }
        val fillIn = Intent().apply {
            data = Uri.parse("jobplanner://home")
        }
        views.setOnClickFillInIntent(R.id.widget_row_root, fillIn)

        val eventId = row?.second.orEmpty()
        if (eventId.isEmpty()) {
            views.setViewVisibility(R.id.widget_row_complete, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_row_complete, View.VISIBLE)
            val complete = Intent().apply {
                data = Uri.parse("jobplanner://complete?id=${Uri.encode(eventId)}")
            }
            views.setOnClickFillInIntent(R.id.widget_row_complete, complete)
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun decodeRowBitmap(path: String): android.graphics.Bitmap? {
        val density = context.resources.displayMetrics.densityDpi
        val options = BitmapFactory.Options().apply {
            inScaled = true
            inDensity = density
            inTargetDensity = density
            inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(path, options)
    }

    private fun rowCount(prefs: android.content.SharedPreferences): Int {
        return try {
            prefs.getInt("${kind}_row_count", 0)
        } catch (_: ClassCastException) {
            prefs.getString("${kind}_row_count", "0")?.toIntOrNull() ?: 0
        }
    }
}
