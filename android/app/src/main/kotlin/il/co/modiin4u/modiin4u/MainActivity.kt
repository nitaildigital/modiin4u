package il.co.modiin4u.modiin4u

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    /**
     * Ask for the display's fastest refresh rate.
     *
     * Some Android skins, ColorOS among them, leave an app at 60 Hz unless it
     * asks for more, even on a 90 Hz or 120 Hz panel. Everything else on the
     * phone then runs smoother than this app for no reason we control from
     * Dart, so the request is made here on the window itself.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        // Before super, so the mode is already in place when the Flutter
        // engine reads the display's refresh rate — set it afterwards and the
        // engine keeps pacing at whatever it saw first.
        requestFastestRefreshRate()
        super.onCreate(savedInstanceState)
    }

    private fun requestFastestRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        @Suppress("DEPRECATION")
        val modes = windowManager.defaultDisplay?.supportedModes ?: return
        val fastest = modes.maxByOrNull { it.refreshRate } ?: return

        window.attributes = window.attributes.apply {
            preferredDisplayModeId = fastest.modeId
        }
    }
}
