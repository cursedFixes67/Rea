package com.dreamreader.app

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Bundle
import android.webkit.*
import android.widget.*
import android.view.ViewGroup
import java.net.URI

/** Interactive site authentication shares the extension process CookieManager; no native JS bridge. */
class SourceWebActivity : Activity() {
    private var browser: WebView? = null
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = runCatching { ExtensionRuntime.get(this).homeUrl(intent.getStringExtra("sourceId") ?: "") }.getOrElse { finish(); return }
        if (runCatching { URI(url).scheme }.getOrNull() !in listOf("https", "http")) { finish(); return }
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(0, 32, 0, 16) }
        val bar = LinearLayout(this)
        bar.addView(Button(this).apply { text = "Done"; setOnClickListener { CookieManager.getInstance().flush(); finish() } })
        bar.addView(TextView(this).apply { text = URI(url).host; setPadding(16, 16, 8, 8) })
        layout.addView(bar)
        browser = WebView(this).apply {
            settings.javaScriptEnabled = true; settings.domStorageEnabled = true
            settings.allowFileAccess = false; settings.allowContentAccess = false
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            settings.setSupportMultipleWindows(false)
            settings.userAgentString = ExtensionRuntime.get(this@SourceWebActivity).userAgent()
            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean = request.url.scheme !in listOf("https", "http")
                override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean { browser = null; view.destroy(); finish(); return true }
            }
            loadUrl(url)
        }
        layout.addView(browser, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(layout)
    }
    override fun onDestroy() { browser?.stopLoading(); browser?.destroy(); browser = null; super.onDestroy() }
}
