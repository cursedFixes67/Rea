package com.dreamreader.app

import android.app.Activity
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat

/** Native source screens follow the app's light/dark choice and system insets. */
internal object SourceChrome {
    fun theme(activity: Activity) {
        activity.setTheme(if (activity.intent.getBooleanExtra("dreamLight", false))
            R.style.SourceLightTheme else R.style.SourceDarkTheme)
    }
    fun insets(activity: Activity, root: View) {
        val light = activity.intent.getBooleanExtra("dreamLight", false)
        WindowCompat.getInsetsController(activity.window, activity.window.decorView).apply {
            isAppearanceLightStatusBars = light
            isAppearanceLightNavigationBars = light
        }
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        ViewCompat.requestApplyInsets(root)
    }
    fun dp(activity: Activity, value: Int) = (value * activity.resources.displayMetrics.density).toInt()
}
