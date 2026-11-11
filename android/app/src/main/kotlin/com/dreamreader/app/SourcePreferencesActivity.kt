package com.dreamreader.app
import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import androidx.preference.PreferenceFragmentCompat

class SourcePreferencesActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) supportFragmentManager.beginTransaction().replace(android.R.id.content,
            SourcePreferencesFragment().apply { arguments = Bundle().apply { putString("sourceId", intent.getStringExtra("sourceId")) } }).commit()
    }
}
class SourcePreferencesFragment : PreferenceFragmentCompat() {
    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        try {
            val source = ExtensionRuntime.get(requireContext()).configurableSource(requireArguments().getString("sourceId")!!)
            preferenceManager.sharedPreferencesName = "source_${source.id}"
            val screen = preferenceManager.createPreferenceScreen(requireContext())
            source.setupPreferenceScreen(screen); preferenceScreen = screen
        } catch (error: Throwable) {
            preferenceScreen = preferenceManager.createPreferenceScreen(requireContext()).apply {
                addPreference(androidx.preference.Preference(context).apply { title = "Source preferences unavailable"; summary = error.message })
            }
        }
    }
}
