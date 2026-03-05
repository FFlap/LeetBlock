package com.leetblock.leet_block

import android.content.Context
import android.os.Looper
import org.json.JSONArray
import org.json.JSONObject
import org.robolectric.Robolectric
import org.robolectric.Shadows.shadowOf
import java.time.Duration
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

internal object AppBlockerServiceTestHarness {
    const val prefsName = "FlutterSharedPreferences"
    const val blockedPackage = "com.example.blocked"
    private const val defaultUsername = "offline-tester"

    fun buildService(): AppBlockerService {
        val service = Robolectric.buildService(AppBlockerService::class.java).create().get()
        service.overlayPermissionChecker = { true }
        service.backgroundExecutor = { runnable -> runnable.run() }
        return service
    }

    fun seedPrefs(
        service: AppBlockerService,
        dailyQuota: Int = 2,
        completed: Int = 0,
        penalty: Int = 0,
        dateIso: String = isoNow(),
        username: String? = defaultUsername,
        penaltyEnabled: Boolean = true,
        penaltyThresholdMins: Int = 10,
        penaltyIncrement: Int = 1,
        strictMode: Boolean = false,
        blockedApps: Set<String> = setOf(blockedPackage),
    ) {
        val blockedAppsJson = JSONArray()
        for (pkg in blockedApps) {
            blockedAppsJson.put(
                JSONObject()
                    .put("packageName", pkg)
                    .put("isBlocked", true),
            )
        }

        val progress = JSONObject()
            .put("date", dateIso)
            .put("questionsCompletedToday", completed)
            .put("manualOffset", 0)
            .put("quotaPenalty", penalty)
            .put("dailyQuota", dailyQuota)
            .put("startOfDayTotal", 0)

        val editor = prefs(service).edit()
        editor
            .putString("flutter.blocked_apps", blockedAppsJson.toString())
            .putString("flutter.daily_progress", progress.toString())
            .putInt("flutter.daily_quota", dailyQuota)
            .putBoolean("flutter.penalty_enabled", penaltyEnabled)
            .putInt("flutter.penalty_threshold_mins", penaltyThresholdMins)
            .putInt("flutter.penalty_increment", penaltyIncrement)
            .putBoolean("flutter.strict_mode", strictMode)
            .putString("flutter.block_message", "LOCK IN")
        if (username == null) {
            editor.remove("flutter.leetcode_username")
        } else {
            editor.putString("flutter.leetcode_username", username)
        }
        editor.commit()
    }

    fun prefs(service: AppBlockerService) =
        service.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    fun readDailyProgress(service: AppBlockerService): JSONObject {
        val json = prefs(service).getString("flutter.daily_progress", "{}") ?: "{}"
        return JSONObject(json)
    }

    fun idleMainLooper() {
        shadowOf(Looper.getMainLooper()).idle()
    }

    fun advanceMainLooper(duration: Duration) {
        shadowOf(Looper.getMainLooper()).idleFor(duration)
    }

    fun isoNow(nowMillis: Long = System.currentTimeMillis()): String {
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date(nowMillis))
    }

    fun isoForDaysAgo(daysAgo: Int, nowMillis: Long = System.currentTimeMillis()): String {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMillis
            add(Calendar.DAY_OF_YEAR, -daysAgo)
        }
        return isoNow(calendar.timeInMillis)
    }

    fun dateKey(nowMillis: Long = System.currentTimeMillis()): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(nowMillis))
    }
}
