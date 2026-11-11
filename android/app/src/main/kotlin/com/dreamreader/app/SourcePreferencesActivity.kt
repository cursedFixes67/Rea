package com.dreamreader.app
import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import androidx.preference.PreferenceFragmentCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.*

class SourcePreferencesActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) supportFragmentManager.beginTransaction().replace(android.R.id.content,
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
