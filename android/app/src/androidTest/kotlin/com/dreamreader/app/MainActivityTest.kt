package com.dreamreader.app

import androidx.test.rule.ActivityTestRule
import dev.flutter.plugins.integration_test.FlutterTestRunner
import org.junit.Rule
import org.junit.runner.RunWith

/** Uses native instrumentation so the journey also runs against release/R8 builds. */
@RunWith(FlutterTestRunner::class)
class MainActivityTest {
    @Rule @JvmField
    val rule = ActivityTestRule(MainActivity::class.java, true, false)
}
