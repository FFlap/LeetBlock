package com.leetblock.leet_block

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isSetupComplete = prefs.getBoolean("flutter.is_setup_complete", false)
        if (!shouldStartBlockerService(intent.action, isSetupComplete)) {
            return
        }

        val serviceIntent = Intent(context, AppBlockerService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}

internal fun shouldStartBlockerService(action: String?, isSetupComplete: Boolean): Boolean {
    if (!isSetupComplete) {
        return false
    }
    return action == Intent.ACTION_BOOT_COMPLETED ||
        action == "android.intent.action.QUICKBOOT_POWERON" ||
        action == "com.htc.intent.action.QUICKBOOT_POWERON"
}
