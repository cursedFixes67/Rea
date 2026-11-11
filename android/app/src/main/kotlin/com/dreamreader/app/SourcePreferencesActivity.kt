package com.dreamreader.app
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import android.widget.LinearLayout
import android.widget.FrameLayout
import android.view.ViewGroup
import androidx.preference.PreferenceFragmentCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.*

class SourcePreferencesActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        SourceChrome.theme(this)
        super.onCreate(savedInstanceState)
        val root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(Toolbar(this).apply {
            title = "Source preferences"
            setNavigationIcon(androidx.appcompat.R.drawable.abc_ic_ab_back_material)
            navigationContentDescription = "Back"
            setNavigationOnClickListener { finish() }
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, SourceChrome.dp(this, 56)))
        root.addView(FrameLayout(this).apply { id = R.id.source_preferences_content },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
        SourceChrome.insets(this, root)
        if (savedInstanceState == null) supportFragmentManager.beginTransaction().replace(R.id.source_preferences_content,
            SourcePreferencesFragment().apply { arguments = Bundle().apply { putString("sourceId", intent.getStringExtra("sourceId")) } }).commit()
    }
}
class SourcePreferencesFragment : PreferenceFragmentCompat() {
    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        preferenceScreen = preferenceManager.createPreferenceScreen(requireContext()).apply {
            addPreference(androidx.preference.Preference(context).apply { title = "Loading source preferences…"; isEnabled = false })
        }
        lifecycleScope.launch {
            try {
                val context = requireContext().applicationContext
                val id = requireArguments().getString("sourceId") ?: error("Missing source")
                val source = withContext(Dispatchers.IO) { ExtensionRuntime.get(context).configurableSource(id) }
                if (!isAdded) return@launch
                preferenceManager.sharedPreferencesName = "source_${source.id}"
                val screen = preferenceManager.createPreferenceScreen(requireContext())
                source.setupPreferenceScreen(screen); preferenceScreen = screen
            } catch (cancelled: CancellationException) { throw cancelled }
            catch (error: Throwable) {
                if (isAdded) preferenceScreen = preferenceManager.createPreferenceScreen(requireContext()).apply {
                    addPreference(androidx.preference.Preference(context).apply { title = "Source preferences unavailable"; summary = SourceErrors.describe(error) })
                }
            }
        }
    }
}
