package com.pluto.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.text.TextPaint
import android.text.TextUtils
import java.io.File
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

object WidgetLabel {
    fun typeface(path: String?): Typeface? {
        val file = path?.takeIf { it.isNotEmpty() }?.let(::File)?.takeIf { it.exists() }
            ?: return null
        return try {
            Typeface.createFromFile(file)
        } catch (_: Exception) {
            null
        }
    }

    fun draw(
        text: String,
        typeface: Typeface,
        sp: Float,
        color: Int,
        density: Float,
        maxWidthPx: Int,
    ): Bitmap {
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            this.typeface = typeface
            textSize = sp * density
            this.color = color
            isLinearText = true
        }
        val widthLimit = max(1, maxWidthPx).toFloat()
        val shown = TextUtils.ellipsize(
            text,
            paint,
            widthLimit,
            TextUtils.TruncateAt.END,
        ).toString()
        val width = max(1, min(maxWidthPx, ceil(paint.measureText(shown)).toInt()))
        val fm = paint.fontMetrics
        val height = max(1, ceil(fm.descent - fm.ascent).toInt())
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.density = Bitmap.DENSITY_NONE
        Canvas(bitmap).drawText(shown, 0f, -fm.ascent, paint)
        return bitmap
    }
}
