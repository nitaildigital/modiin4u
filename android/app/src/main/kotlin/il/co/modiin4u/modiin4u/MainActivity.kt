package il.co.modiin4u.modiin4u

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// A FlutterFragmentActivity because Health Connect's permission screen is
// opened through registerForActivityResult, which only a ComponentActivity
// has; the `health` plugin cannot ask for step data from a plain
// FlutterActivity.
class MainActivity : FlutterFragmentActivity() {

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
        createNotificationChannel()
    }

    /**
     * The channel push notifications arrive on (`channel_id` in
     * supabase/functions/push-dispatch). Without it Firebase files them under
     * a channel of its own called "Miscellaneous", which is what the person
     * would see in the phone's settings when choosing what to silence.
     * Creating it again on every start is harmless; it also renames it if
     * the phone's language changed.
     */
    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            "general",
            getString(R.string.notification_channel_general),
            NotificationManager.IMPORTANCE_HIGH,
        )
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
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
