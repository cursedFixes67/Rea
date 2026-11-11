package com.dreamreader.app

import android.annotation.SuppressLint
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.*
import android.os.Bundle
import android.text.TextUtils
import android.webkit.*
import android.widget.*
import android.view.View
import android.view.ViewGroup
import java.net.URI

/** Interactive site authentication shares cookies with sources; no native JS bridge. */
class SourceWebActivity : ComponentActivity() {
    private var browser: WebView? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        SourceChrome.theme(this)
        super.onCreate(savedInstanceState)
        val loading = TextView(this).apply { text = "Opening source website…"; textSize = 16f }
        val frame = FrameLayout(this).apply {
            addView(loading, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                setMargins(SourceChrome.dp(this@SourceWebActivity, 24), SourceChrome.dp(this@SourceWebActivity, 24), SourceChrome.dp(this@SourceWebActivity, 24), 0)
            })
        }
        setContentView(frame)
        SourceChrome.insets(this, frame)
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val page = browser
                if (page?.canGoBack() == true) page.goBack() else finish()
            }
        })
        lifecycleScope.launch {
            try {
                val url = withContext(Dispatchers.IO) { ExtensionRuntime.get(this@SourceWebActivity).homeUrl(intent.getStringExtra("sourceId") ?: "") }
                check(runCatching { URI(url).scheme }.getOrNull() in listOf("https", "http")) { "This source has no supported website address" }
                if (!isFinishing) open(url)
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (error: Throwable) { loading.text = "Could not open this source: ${SourceErrors.describe(error)}" }
        }
    }
    @SuppressLint("SetJavaScriptEnabled")
    private fun open(url: String) {
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        val bar = LinearLayout(this).apply { gravity = android.view.Gravity.CENTER_VERTICAL }
        val host = TextView(this).apply {
            text = URI(url).host; maxLines = 1; ellipsize = TextUtils.TruncateAt.END
            setPadding(SourceChrome.dp(this@SourceWebActivity, 8), 0, SourceChrome.dp(this@SourceWebActivity, 8), 0)
        }
        bar.addView(actionButton("Close website", android.R.drawable.ic_menu_close_clear_cancel) { finish() },
            LinearLayout.LayoutParams(SourceChrome.dp(this, 48), SourceChrome.dp(this, 48)))
        bar.addView(host, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
        bar.addView(actionButton("Reload website", android.R.drawable.ic_popup_sync) { browser?.reload() },
            LinearLayout.LayoutParams(SourceChrome.dp(this, 48), SourceChrome.dp(this, 48)))
        layout.addView(bar)
        val progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal)
        layout.addView(progress, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, SourceChrome.dp(this, 2)))
        browser = WebView(this).apply {
            settings.javaScriptEnabled = true; settings.domStorageEnabled = true
            settings.allowFileAccess = false; settings.allowContentAccess = false
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            settings.setSupportMultipleWindows(false)
            settings.userAgentString = ExtensionRuntime.get(this@SourceWebActivity).userAgent()
            webChromeClient = object : WebChromeClient() {
                override fun onProgressChanged(view: WebView, value: Int) {
                    progress.progress = value; progress.visibility = if (value < 100) View.VISIBLE else View.INVISIBLE
                }
            }
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean = request.url.scheme !in listOf("https", "http")
                override fun onPageStarted(view: WebView, address: String, favicon: android.graphics.Bitmap?) {
                    host.text = runCatching { URI(address).host }.getOrNull() ?: "Source website"
                }
                override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean { browser = null; (view.parent as? ViewGroup)?.removeView(view); view.destroy(); finish(); return true }
            }
            loadUrl(url)
        }
        layout.addView(browser, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(layout)
        SourceChrome.insets(this, layout)
    }
    private fun actionButton(label: String, icon: Int, action: () -> Unit) = ImageButton(this).apply {
        contentDescription = label; tooltipText = label; setImageResource(icon)
        imageTintList = android.content.res.ColorStateList.valueOf(
            if (intent.getBooleanExtra("dreamLight", false)) 0xFF152027.toInt() else 0xFFF0F5F3.toInt())
        val background = android.util.TypedValue()
        theme.resolveAttribute(android.R.attr.selectableItemBackgroundBorderless, background, true)
        setBackgroundResource(background.resourceId)
        setOnClickListener { action() }
    }
    override fun onStop() { runCatching { CookieManager.getInstance().flush() }; super.onStop() }
    override fun onDestroy() { browser?.stopLoading(); browser?.destroy(); browser = null; super.onDestroy() }
}
