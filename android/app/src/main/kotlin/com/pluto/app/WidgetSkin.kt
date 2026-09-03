package com.pluto.app

import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import java.io.File

object WidgetSkin {
    const val BACKGROUND_KEY = "widget_skin_bg"

    fun apply(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        dark: Boolean,
        rootId: Int,
        imageId: Int,
        showImage: Boolean = true,
    ) {
        if (!showImage) {
            views.setViewVisibility(imageId, View.GONE)
            views.setInt(rootId, "setBackgroundColor", Color.TRANSPARENT)
            return
        }
        val bitmap = decode(context, widgetData.getString(BACKGROUND_KEY, null))
        if (bitmap != null) {
            views.setImageViewBitmap(imageId, bitmap)
            views.setViewVisibility(imageId, View.VISIBLE)
            views.setInt(rootId, "setBackgroundColor", Color.TRANSPARENT)
        } else {
            views.setViewVisibility(imageId, View.GONE)
            views.setInt(
                rootId,
                "setBackgroundResource",
                if (dark) R.drawable.widget_card_dark else R.drawable.widget_card_light,
            )
        }
    }

    fun decode(context: Context, path: String?): android.graphics.Bitmap? {
        val file = path?.takeIf { File(it).exists() } ?: return null
        val density = context.resources.displayMetrics.densityDpi
        val options = BitmapFactory.Options().apply {
            inScaled = true
            inDensity = density
            inTargetDensity = density
            inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(file, options)
    }

    fun decodeUnscaled(path: String?): android.graphics.Bitmap? {
        val file = path?.takeIf { File(it).exists() } ?: return null
        val options = BitmapFactory.Options().apply {
            inScaled = false
            inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeFile(file, options)?.apply {
            density = android.graphics.Bitmap.DENSITY_NONE
        }
    }
}
