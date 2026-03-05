package com.leetblock.leet_block

import android.app.*
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView
import androidx.annotation.VisibleForTesting
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors

internal data class UsageSnapshot(
    val totalBlockedTimeMs: Long,
    val perAppTimeMs: Map<String, Long>,
)

class AppBlockerService : Service() {
    
    companion object {
        private const val TAG = "LeetBlockService"
        private const val CHANNEL_ID = "LeetBlockService"
        private const val CHANNEL_ID_WARNING = "LeetBlockServiceWarning"
        private const val NOTIFICATION_ID = 1001
        private const val WARNING_NOTIFICATION_ID = 1002
        private const val PERMISSION_NOTIFICATION_ID = 1003
        private const val CHECK_INTERVAL = 250L
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val LEETCODE_API = "https://leetcode.com/graphql"
    }
    
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var isOverlayShowing = false
    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundApp: String? = null
    private var currentlyBlockingApp: String? = null
    private val executor = Executors.newSingleThreadExecutor()
    private var penaltyCheckCounter = 0

    private val PENALTY_CHECK_TICKS = 20 // Check every ~5 seconds (20 * 250ms)
    private var lastWarningMultiplier = -1
    private var lastWarningDay = -1  // Track day of year for resetting warnings

    // Internal test hooks (defaults preserve production behavior)
    @VisibleForTesting internal var foregroundAppResolver: (() -> String?)? = null
    @VisibleForTesting internal var overlayPermissionChecker: (() -> Boolean)? = null
    @VisibleForTesting internal var todaySubmissionsFetcher: ((String) -> Int)? = null
    @VisibleForTesting internal var usageSnapshotProvider: ((Set<String>) -> UsageSnapshot)? = null
    @VisibleForTesting internal var backgroundExecutor: ((Runnable) -> Unit)? = null
    @VisibleForTesting internal var penaltyWarningObserver: ((Int) -> Unit)? = null
    @VisibleForTesting internal var nowMillisProvider: (() -> Long)? = null

    // UI elements we need to update
    private var remainingTextView: TextView? = null
    private var moreTextView: TextView? = null
    private var checkProgressBtn: Button? = null
    private var statusTextView: TextView? = null

    private val checkRunnable = object : Runnable {
        override fun run() {
            try {
                checkForegroundApp()
                
                // Check penalty periodically
                penaltyCheckCounter++
                if (penaltyCheckCounter >= PENALTY_CHECK_TICKS) {
                    penaltyCheckCounter = 0
                    checkPenaltyInBackground()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in checkForegroundApp", e)
            }
            handler.postDelayed(this, CHECK_INTERVAL)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        if (!hasRequiredPermissions()) {
            Log.w(TAG, "Missing required permissions; stopping service")
            sendMissingPermissionsNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        handler.removeCallbacks(checkRunnable)
        hideOverlay()
        executor.shutdown()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "LeetBlock App Blocker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors app usage for LeetBlock"
                setShowBadge(false)
            }
            
            val warningChannel = NotificationChannel(
                CHANNEL_ID_WARNING,
                "LeetBlock Warnings",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Warnings for LeetBlock penalties"
                setShowBadge(true)
                enableVibration(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            notificationManager.createNotificationChannel(warningChannel)
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !canDrawOverlays()) {
            return false
        }

        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("LeetBlock Active")
            .setContentText("Blocking apps until quota is met")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun sendPenaltyWarningNotification(minutesRemaining: Int) {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_WARNING)
            .setContentTitle("Penalty Warning")
            .setContentText("Only $minutesRemaining min${if (minutesRemaining != 1) "s" else ""} left until penalty!")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        penaltyWarningObserver?.invoke(minutesRemaining)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(WARNING_NOTIFICATION_ID, notification)
    }

    private fun sendMissingPermissionsNotification() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_WARNING)
            .setContentTitle("LeetBlock Paused")
            .setContentText("Grant usage and overlay permissions to resume blocking.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(PERMISSION_NOTIFICATION_ID, notification)
    }

    private fun checkForegroundApp(forceUpdate: Boolean = false) {
        if (!canDrawOverlays()) {
            return
        }
        
        var foregroundApp = getForegroundAppPackage()
        
        if (foregroundApp == null) {
            return
        }
        
        if (foregroundApp != lastForegroundApp) {
            Log.d(TAG, "Foreground: $foregroundApp")
            lastForegroundApp = foregroundApp
        }
        
        val blockedApps = getBlockedApps()
        val isBlocked = blockedApps.contains(foregroundApp)
        val quotaMet = isQuotaMet()
        val strictMode = isStrictModeEnabled()
        
        // In strict mode, block our own app too
        val shouldBlockOurApp = strictMode && foregroundApp == this.packageName && !quotaMet
        
        if ((isBlocked || shouldBlockOurApp) && !quotaMet) {
            currentlyBlockingApp = foregroundApp
            // Show if not showing OR if forced (to update penalty text)
            if (!isOverlayShowing || forceUpdate) {
                Log.d(TAG, "BLOCKING: $foregroundApp (force=$forceUpdate)")
                showBlockingOverlay(foregroundApp)
            }
            return
        }
        
        if (isOverlayShowing && currentlyBlockingApp != null && !forceUpdate) {
            if (isLauncherOrRecents(foregroundApp)) {
                Log.d(TAG, "On recents/launcher - keeping overlay for $currentlyBlockingApp")
                return
            }
            
            // If the overlay took focus, the foreground app is US. 
            // We should not hide the overlay in this case.
            if (foregroundApp == this.packageName) {
                Log.d(TAG, "Overlay is focused (blocking $currentlyBlockingApp) - keeping it")
                return
            }
        }
        
        if (isOverlayShowing) {
            if (isSafeApp(foregroundApp)) {
                Log.d(TAG, "Safe app: $foregroundApp - hiding overlay")
                hideOverlay()
                currentlyBlockingApp = null
            } else if (!isLauncherOrRecents(foregroundApp) && !isBlocked) {
                Log.d(TAG, "Non-blocked app: $foregroundApp - hiding overlay")
                hideOverlay()
                currentlyBlockingApp = null
            }
        }
    }
    
    private fun isLauncherOrRecents(packageName: String): Boolean {
        return packageName.contains("launcher") ||
               packageName.contains("systemui") ||
               packageName == "com.google.android.apps.nexuslauncher" ||
               packageName == "com.android.launcher" ||
               packageName == "com.android.launcher3"
    }
    
    private fun isStrictModeEnabled(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean("flutter.strict_mode", false)
    }
    
    private fun isSafeApp(packageName: String): Boolean {
        // In strict mode, our own app is NOT safe - it gets blocked too
        val isOurApp = packageName == this.packageName
        if (isOurApp && isStrictModeEnabled()) {
            return false  // Block our own app in strict mode
        }
        
        return isOurApp ||
               packageName == "com.android.settings" ||
               packageName.contains("chrome") ||
               packageName.contains("browser") ||
               packageName.contains("firefox") ||
               packageName.contains("edge") ||
               packageName.contains("opera") ||
               packageName.contains("brave")
    }

    private fun getForegroundAppPackage(): String? {
        foregroundAppResolver?.let { return it.invoke() }

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = nowMillis()
        val startTime = endTime - 1000 * 60 * 5
        
        try {
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            if (usageStatsList != null && usageStatsList.isNotEmpty()) {
                val sortedMap: SortedMap<Long, UsageStats> = TreeMap()
                for (usageStats in usageStatsList) {
                    sortedMap[usageStats.lastTimeUsed] = usageStats
                }
                
                if (sortedMap.isNotEmpty()) {
                    val recentStats = sortedMap[sortedMap.lastKey()]
                    if (recentStats != null) {
                        val timeSinceUsed = endTime - recentStats.lastTimeUsed
                        if (timeSinceUsed < 3000) {
                            return recentStats.packageName
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error with queryUsageStats", e)
        }
        
        try {
            val usageEvents = usageStatsManager.queryEvents(endTime - 10000, endTime)
            var lastPackage: String? = null
            var lastTime: Long = 0
            
            val event = android.app.usage.UsageEvents.Event()
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED ||
                    event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    if (event.timeStamp > lastTime) {
                        lastPackage = event.packageName
                        lastTime = event.timeStamp
                    }
                }
            }
            
            if (lastPackage != null) {
                return lastPackage
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error with queryEvents", e)
        }
        
        return null
    }

    private fun getBlockedApps(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockedAppsJson = prefs.getString("flutter.blocked_apps", null) ?: return emptySet()
        
        try {
            val jsonArray = JSONArray(blockedAppsJson)
            val blockedSet = mutableSetOf<String>()
            
            for (i in 0 until jsonArray.length()) {
                val app = jsonArray.getJSONObject(i)
                if (app.optBoolean("isBlocked", false)) {
                    blockedSet.add(app.getString("packageName"))
                }
            }
            
            return blockedSet
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing blocked apps", e)
            return emptySet()
        }
    }

    private fun getUsername(): String? {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("flutter.leetcode_username", null)
    }

    private fun getTodayDateKey(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(nowMillis()))
    }

    private fun getNowTimestampIso(): String {
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date(nowMillis()))
    }

    private fun nowMillis(): Long {
        return nowMillisProvider?.invoke() ?: System.currentTimeMillis()
    }

    private fun canDrawOverlays(): Boolean {
        return overlayPermissionChecker?.invoke() ?: Settings.canDrawOverlays(this)
    }

    private fun runInBackground(work: () -> Unit) {
        val runnable = Runnable { work() }
        backgroundExecutor?.invoke(runnable) ?: executor.execute(runnable)
    }

    private fun getNormalizedDailyProgress(prefs: android.content.SharedPreferences): JSONObject {
        val progressJson = prefs.getString("flutter.daily_progress", null)
        val parsedProgress = try {
            if (progressJson.isNullOrEmpty()) null else JSONObject(progressJson)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing daily progress JSON, resetting", e)
            null
        }

        val baseQuota = getIntFromPrefs(prefs, "flutter.daily_quota", 1).coerceAtLeast(1)
        val normalized = DailyProgressStore.normalize(
            current = parsedProgress,
            baseQuota = baseQuota,
            todayKey = getTodayDateKey(),
            nowIso = getNowTimestampIso(),
        )

        if (normalized.changed) {
            prefs.edit().putString("flutter.daily_progress", normalized.progress.toString()).apply()
        }

        return normalized.progress
    }

    private fun getQuotaSnapshot(prefs: android.content.SharedPreferences): DailyProgressSnapshot {
        val progress = getNormalizedDailyProgress(prefs)
        val baseQuota = getIntFromPrefs(prefs, "flutter.daily_quota", 1).coerceAtLeast(1)
        return DailyProgressStore.snapshot(progress, baseQuota)
    }

    private fun isQuotaMet(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        try {
            val snapshot = getQuotaSnapshot(prefs)
            return snapshot.completed >= snapshot.totalQuota
        } catch (e: Exception) {
            Log.e(TAG, "Error checking quota", e)
            return false
        }
    }

    // Check if BASE quota is met (ignoring penalty) - used for weekly goal tracking
    private fun isBaseQuotaMet(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        try {
            val snapshot = getQuotaSnapshot(prefs)
            return snapshot.completed >= snapshot.baseQuota
        } catch (e: Exception) {
            Log.e(TAG, "Error checking base quota", e)
            return false
        }
    }





    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun createRoundedBackground(colorHex: String, radiusDp: Float): android.graphics.drawable.GradientDrawable {
        val drawable = android.graphics.drawable.GradientDrawable()
        drawable.setColor(Color.parseColor(colorHex))
        drawable.cornerRadius = radiusDp * resources.displayMetrics.density
        return drawable
    }

    private fun getIntFromPrefs(prefs: android.content.SharedPreferences, key: String, defaultValue: Int): Int {
        return try {
            prefs.getInt(key, defaultValue)
        } catch (e: ClassCastException) {
            try {
                prefs.getLong(key, defaultValue.toLong()).toInt()
            } catch (e2: Exception) {
                defaultValue
            }
        }
    }

    private fun getBlockMessage(): String {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("flutter.block_message", "LOCK IN") ?: "LOCK IN"
    }

    private fun showBlockingOverlay(packageName: String) {
        handler.post {
            overlayView?.let {
                try { windowManager.removeView(it) } catch (e: Exception) { }
            }
            overlayView = null
            
            val (completed, quota) = getQuotaInfo()
            val remaining = (quota - completed).coerceAtLeast(0)
            val density = resources.displayMetrics.density
            val blockMessage = getBlockMessage()
            
            // Main container - ScrollView for landscape support
            val scrollView = ScrollView(this).apply {
                isFillViewport = true
                setBackgroundColor(Color.BLACK)
                isClickable = true
                isFocusable = true
                isFocusableInTouchMode = true
                setOnKeyListener { _, keyCode, _ ->
                    keyCode == android.view.KeyEvent.KEYCODE_BACK
                }
            }

            // Content layout
            val layout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setBackgroundColor(Color.TRANSPARENT)
                setPadding((40 * density).toInt(), (20 * density).toInt(), (40 * density).toInt(), (20 * density).toInt())
            }
            
            scrollView.addView(layout)
            
            // Spacer to push content to center
            layout.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(1, 0, 1f)
            })
            
            // Main message - big and bold
            val messageText = TextView(this).apply {
                text = blockMessage
                textSize = 42f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setTypeface(android.graphics.Typeface.DEFAULT_BOLD)
                letterSpacing = 0.15f
            }
            layout.addView(messageText)
            
            // Spacer
            layout.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(1, (40 * density).toInt())
            })
            
            // Remaining count
            remainingTextView = TextView(this).apply {
                text = "$remaining"
                textSize = 72f
                setTextColor(Color.parseColor("#FFA116"))
                gravity = Gravity.CENTER
                setTypeface(android.graphics.Typeface.MONOSPACE, android.graphics.Typeface.BOLD)
            }
            layout.addView(remainingTextView)
            
            moreTextView = TextView(this).apply {
                text = "problem${if (remaining != 1) "s" else ""} left"
                textSize = 16f
                setTextColor(Color.parseColor("#666666"))
                gravity = Gravity.CENTER
                letterSpacing = 0.05f
            }
            layout.addView(moreTextView)
            
            // Status text (for check progress feedback)
            statusTextView = TextView(this).apply {
                text = ""
                textSize = 14f
                setTextColor(Color.parseColor("#666666"))
                gravity = Gravity.CENTER
                setPadding(0, (24 * density).toInt(), 0, 0)
            }
            layout.addView(statusTextView)
            
            // Spacer to push buttons to bottom
            layout.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(1, 0, 1f)
            })
            
            // Buttons container - minimal style
            val buttonsLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            
            // Check Progress - subtle text button
            checkProgressBtn = Button(this).apply {
                text = "Check Progress"
                textSize = 14f
                setTextColor(Color.parseColor("#FFA116"))
                setBackgroundColor(Color.TRANSPARENT)
                isAllCaps = false
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    gravity = Gravity.CENTER
                }
                setOnClickListener { checkLeetCodeProgress() }
            }
            buttonsLayout.addView(checkProgressBtn)
            
            buttonsLayout.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(1, (16 * density).toInt())
            })
            
            // Open LeetCode button - primary action
            val leetCodeBtn = Button(this).apply {
                text = "Open LeetCode"
                textSize = 16f
                setTextColor(Color.BLACK)
                background = createRoundedBackground("#FFA116", 25f)
                setPadding((48 * density).toInt(), (16 * density).toInt(), (48 * density).toInt(), (16 * density).toInt())
                isAllCaps = false
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    gravity = Gravity.CENTER
                }
                setOnClickListener { openLeetCode() }
            }
            buttonsLayout.addView(leetCodeBtn)
            
            buttonsLayout.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(1, (16 * density).toInt())
            })
            
            // Go Home - minimal text
            val homeBtn = Button(this).apply {
                text = "Go Home"
                textSize = 14f
                setTextColor(Color.parseColor("#444444"))
                setBackgroundColor(Color.TRANSPARENT)
                isAllCaps = false
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    gravity = Gravity.CENTER
                }
                setOnClickListener { goHome() }
            }
            buttonsLayout.addView(homeBtn)
            
            layout.addView(buttonsLayout)
            
            overlayView = scrollView
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.OPAQUE
            )
            params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
            params.screenOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            
            try {
                windowManager.addView(overlayView, params)
                isOverlayShowing = true
                Log.d(TAG, "Overlay SHOWN for $packageName")
            } catch (e: Exception) {
                Log.e(TAG, "Error showing overlay", e)
            }
        }
    }

    private fun checkLeetCodeProgress() {
        val username = getUsername()
        if (username.isNullOrEmpty()) {
            handler.post {
                statusTextView?.text = "No username configured"
                statusTextView?.setTextColor(Color.parseColor("#F85149"))
            }
            return
        }
        
        // Update UI to show loading
        handler.post {
            checkProgressBtn?.isEnabled = false
            checkProgressBtn?.text = "Checking..."
            statusTextView?.text = ""
        }
        
        // Fetch from LeetCode in background
        runInBackground {
            try {
                val todaySubmissions = fetchTodaySubmissions(username)
                
                if (todaySubmissions >= 0) {
                    // Calculate penalty
                    val penalty = calculatePenalty()
                    
                    // Update SharedPreferences
                    updateDailyProgress(todaySubmissions, penalty)
                    
                    val (completed, quota) = getQuotaInfo()
                    val remaining = (quota - completed).coerceAtLeast(0)
                    
                    handler.post {
                        if (completed >= quota) {
                            // Quota met! Hide overlay
                            statusTextView?.text = "Quota met! Unlocking..."
                            statusTextView?.setTextColor(Color.parseColor("#3FB950"))
                            
                            handler.postDelayed({
                                currentlyBlockingApp = null
                                hideOverlay()
                            }, 1000)
                        } else {
                            // Update the display
                            remainingTextView?.text = "$remaining"
                            moreTextView?.text = "problem${if (remaining != 1) "s" else ""} remaining"
                            statusTextView?.text = "Found $todaySubmissions submission${if (todaySubmissions != 1) "s" else ""} today"
                            if (completed != todaySubmissions) {
                                val offset = completed - todaySubmissions
                                val sign = if (offset >= 0) "+" else ""
                                statusTextView?.text = "${statusTextView?.text} ($sign$offset offset)"
                            }
                            
                            if (penalty > 0) {
                                statusTextView?.text = "${statusTextView?.text}\n(+${penalty} penalty from usage)"
                            }
                            
                            statusTextView?.setTextColor(Color.parseColor("#888888"))
                            
                            checkProgressBtn?.isEnabled = true
                            checkProgressBtn?.text = "Check Progress"
                        }
                    }
                } else {
                    handler.post {
                        statusTextView?.text = "Failed to fetch. Try again."
                        statusTextView?.setTextColor(Color.parseColor("#F85149"))
                        checkProgressBtn?.isEnabled = true
                        checkProgressBtn?.text = "Check Progress"
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking progress", e)
                handler.post {
                    statusTextView?.text = "Error: ${e.message}"
                    statusTextView?.setTextColor(Color.parseColor("#F85149"))
                    checkProgressBtn?.isEnabled = true
                    checkProgressBtn?.text = "Check Progress"
                }
            }
        }
    }
    
    private fun fetchTodaySubmissions(username: String): Int {
        todaySubmissionsFetcher?.let { return it.invoke(username) }

        val query = """
            query getUserProfile(${"$"}username: String!) {
                recentAcSubmissionList(username: ${"$"}username, limit: 50) {
                    timestamp
                }
            }
        """.trimIndent()
        
        val url = URL(LEETCODE_API)
        val connection = url.openConnection() as HttpURLConnection
        
        try {
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Referer", "https://leetcode.com")
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            connection.doOutput = true
            
            val body = JSONObject().apply {
                put("query", query)
                put("variables", JSONObject().put("username", username))
            }
            
            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
            }
            
            if (connection.responseCode == 200) {
                val response = BufferedReader(InputStreamReader(connection.inputStream)).use { reader ->
                    reader.readText()
                }
                
                val json = JSONObject(response)
                val submissions = json.getJSONObject("data").optJSONArray("recentAcSubmissionList")
                
                if (submissions == null) {
                    Log.e(TAG, "No submissions array in response")
                    return -1
                }
                
                // Count submissions from today
                val todayStart = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis / 1000  // Convert to seconds
                
                var todayCount = 0
                for (i in 0 until submissions.length()) {
                    val submission = submissions.getJSONObject(i)
                    val timestamp = submission.getString("timestamp").toLong()
                    if (timestamp >= todayStart) {
                        todayCount++
                    }
                }
                
                Log.d(TAG, "Found $todayCount submissions today for $username")
                return todayCount
            } else {
                Log.e(TAG, "HTTP error: ${connection.responseCode}")
                return -1
            }
        } finally {
            connection.disconnect()
        }
    }
    
    private fun updateDailyProgress(todaySubmissions: Int, penalty: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        try {
            val progress = getNormalizedDailyProgress(prefs)
            val baseQuota = getIntFromPrefs(prefs, "flutter.daily_quota", 1).coerceAtLeast(1)
            val merged = DailyProgressStore.mergeSubmissions(
                progress = progress,
                todaySubmissions = todaySubmissions,
                penalty = penalty,
                baseQuota = baseQuota,
                nowIso = getNowTimestampIso(),
            )

            prefs.edit().putString("flutter.daily_progress", merged.toString()).apply()
            Log.d(TAG, "Updated daily progress: $todaySubmissions submissions")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating daily progress", e)
        }
    }

    private fun updatePenaltyOnly(penalty: Int): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        try {
            val progress = getNormalizedDailyProgress(prefs)
            val (merged, changed) = DailyProgressStore.mergePenalty(progress, penalty)
            if (changed) {
                prefs.edit().putString("flutter.daily_progress", merged.toString()).apply()
                Log.d(TAG, "Updated penalty in background: ${penalty.coerceAtLeast(0)}")
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating penalty", e)
        }
        return false
    }

    private fun checkPenaltyInBackground() {
        runInBackground {
            try {
                val penalty = calculatePenalty()
                val changed = updatePenaltyOnly(penalty)
                
                if (changed) {
                    // Force a check immediately so the overlay appears if we are now over quota
                    handler.post { checkForegroundApp(forceUpdate = true) }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking penalty in background", e)
            }
        }
    }

    private fun getQuotaInfo(): Pair<Int, Int> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        try {
            val snapshot = getQuotaSnapshot(prefs)
            return Pair(snapshot.completed, snapshot.totalQuota)
        } catch (e: Exception) {
            Log.e(TAG, "Error getting quota info", e)
            return Pair(0, 1) // Default to 0 completed, 1 quota on error
        }
    }

    private fun calculatePenalty(): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val penaltyEnabled = prefs.getBoolean("flutter.penalty_enabled", false)
        
        val thresholdMins = getIntFromPrefs(prefs, "flutter.penalty_threshold_mins", 30)
        val increment = getIntFromPrefs(prefs, "flutter.penalty_increment", 1)
        
        // Get blocked apps
        val blockedAppsJson = prefs.getString("flutter.blocked_apps", "[]")
        val blockedPackages = mutableListOf<String>()
        try {
            val jsonArray = JSONArray(blockedAppsJson)
            for (i in 0 until jsonArray.length()) {
                val app = jsonArray.getJSONObject(i)
                if (app.optBoolean("isBlocked", false)) {
                    blockedPackages.add(app.getString("packageName"))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing blocked apps", e)
            return 0
        }
        
        if (blockedPackages.isEmpty()) return 0
        
        val usageSnapshot = usageSnapshotProvider?.invoke(blockedPackages.toSet())
            ?: collectUsageSnapshot(blockedPackages.toSet())
        val totalTimeMap = usageSnapshot.perAppTimeMs.toMutableMap()
        val totalBlockedTime = usageSnapshot.totalBlockedTimeMs.coerceAtLeast(0L)
        val contributingApps = StringBuilder()

        for ((pkg, timeMs) in totalTimeMap) {
            if (timeMs > 0) {
                contributingApps.append("$pkg: ${timeMs / 1000 / 60}m, ")
            }
        }
        
        // Save total blocked time for UI display
        prefs.edit().putLong("flutter.total_blocked_time", totalBlockedTime).apply()
        
        // Update daily screen time history
        try {
            val historyJson = prefs.getString("flutter.daily_screen_time_history", "{}")
            val history = JSONObject(historyJson ?: "{}")
            val todayDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date(nowMillis()))
            history.put(todayDate, totalBlockedTime)
            prefs.edit().putString("flutter.daily_screen_time_history", history.toString()).apply()
            
            // Update daily APP usage history (Breakdown)
            val appHistoryJson = prefs.getString("flutter.daily_app_usage_history", "{}")
            val appHistory = JSONObject(appHistoryJson ?: "{}")
            
            // Create JSON object for today's breakdown
            val todayBreakdown = JSONObject()
            for ((pkg, timeMs) in totalTimeMap) {
                if (timeMs > 0) {
                    todayBreakdown.put(pkg, timeMs)
                }
            }
            
            appHistory.put(todayDate, todayBreakdown)
            prefs.edit().putString("flutter.daily_app_usage_history", appHistory.toString()).apply()
            
            // Update daily COMPLETION history (base quota status - ignoring penalty)
            val completionHistoryJson = prefs.getString("flutter.daily_completion_history", "{}")
            val completionHistory = JSONObject(completionHistoryJson ?: "{}")
            val baseQuotaMet = isBaseQuotaMet()
            completionHistory.put(todayDate, baseQuotaMet)
            prefs.edit().putString("flutter.daily_completion_history", completionHistory.toString()).apply()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error saving daily screen time history", e)
        }

        if (totalBlockedTime > 0) {
            Log.d(TAG, "Contributing Apps (Safe Events): $contributingApps")
        }
        
        // If penalty is disabled, return 0 but blocked time is still tracked above
        if (!penaltyEnabled) return 0
        
        val totalMinutes = totalBlockedTime / 1000 / 60
        val penaltyMultipliers = totalMinutes / thresholdMins

        // Reset warning tracker on new day
        val currentDay =
            Calendar.getInstance().apply { timeInMillis = nowMillis() }.get(Calendar.DAY_OF_YEAR)
        if (currentDay != lastWarningDay) {
            lastWarningMultiplier = -1
            lastWarningDay = currentDay
            Log.d(TAG, "New day detected, reset lastWarningMultiplier to -1")
        }

        // Warning Logic
        val currentCycleUsage = totalMinutes % thresholdMins
        val remaining = thresholdMins - currentCycleUsage
        
        // Warn if we are close to the threshold (e.g. 90% used OR only 1-2 mins left)
        // For small thresholds (e.g. 5 mins), 90% is 4.5 mins. We want to warn at 4 mins.
        // So we warn if remaining is small enough.
        val shouldWarn = if (thresholdMins <= 10) {
            remaining <= 1 // For short thresholds, warn when 1 min is left
        } else {
            remaining <= (thresholdMins * 0.1).coerceAtLeast(1.0).toLong() // For larger, warn at 10%
        }

        Log.d(TAG, "Warning check: remaining=$remaining, shouldWarn=$shouldWarn, penaltyMultipliers=$penaltyMultipliers, lastWarningMultiplier=$lastWarningMultiplier")

        if (shouldWarn && remaining > 0 && penaltyMultipliers > lastWarningMultiplier) {
            // We haven't warned for this multiplier cycle yet
            Log.d(TAG, "Sending penalty warning notification: $remaining mins left")
            sendPenaltyWarningNotification(remaining.toInt())
            lastWarningMultiplier = penaltyMultipliers.toInt() // Mark as warned for this cycle
        } else if (penaltyMultipliers > lastWarningMultiplier + 1) {
             // Reset if we somehow skipped ahead
             lastWarningMultiplier = penaltyMultipliers.toInt() - 1
             Log.d(TAG, "Skipped ahead, reset lastWarningMultiplier to $lastWarningMultiplier")
        }
        
        Log.d(TAG, "Penalty Calc: $totalMinutes mins used / $thresholdMins threshold = $penaltyMultipliers multipliers. Increment: $increment")
        
        return (penaltyMultipliers * increment).toInt()
    }

    private fun collectUsageSnapshot(blockedPackages: Set<String>): UsageSnapshot {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMillis()
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = nowMillis()

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = android.app.usage.UsageEvents.Event()

        val lastForegroundTime = mutableMapOf<String, Long>()
        val totalTimeMap = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val packageName = event.packageName

            if (blockedPackages.contains(packageName)) {
                if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    lastForegroundTime[packageName] = event.timeStamp
                } else if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_BACKGROUND) {
                    if (lastForegroundTime.containsKey(packageName)) {
                        val start = lastForegroundTime[packageName]!!
                        val duration = event.timeStamp - start
                        totalTimeMap[packageName] = (totalTimeMap[packageName] ?: 0L) + duration
                        lastForegroundTime.remove(packageName)
                    }
                }
            }
        }

        for ((pkg, start) in lastForegroundTime) {
            val duration = endTime - start
            totalTimeMap[pkg] = (totalTimeMap[pkg] ?: 0L) + duration
        }

        val normalizedMap =
            totalTimeMap
                .filterValues { it > 0 }
                .mapValues { (_, value) -> value.coerceAtLeast(0L) }
        val totalBlockedTime = normalizedMap.values.fold(0L) { acc, value -> acc + value }

        return UsageSnapshot(totalBlockedTimeMs = totalBlockedTime, perAppTimeMs = normalizedMap)
    }

    private fun hideOverlay() {
        handler.post {
            overlayView?.let {
                try {
                    windowManager.removeView(it)
                    Log.d(TAG, "Overlay HIDDEN")
                } catch (e: Exception) { }
            }
            overlayView = null
            isOverlayShowing = false
            remainingTextView = null
            moreTextView = null
            checkProgressBtn = null
            statusTextView = null
        }
    }

    private fun openLeetCode() {
        currentlyBlockingApp = null
        
        // Try to get next problem from study preferences
        val nextProblemUrl = getNextProblemUrl()
        val url = nextProblemUrl ?: "https://leetcode.com/problemset/"
        
        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
    
    private fun getNextProblemUrl(): String? {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            // Get study preferences
            val prefsJson = prefs.getString("flutter.study_preferences", null) ?: return null
            val studyPrefs = org.json.JSONObject(prefsJson)
            val activeListId = studyPrefs.optString("activeListId", "")
            val random = studyPrefs.optBoolean("random", false)
            val unsolvedOnly = studyPrefs.optBoolean("unsolvedOnly", true)
            val easiestFirst = studyPrefs.optBoolean("easiestFirst", false)
            val skipPremium = studyPrefs.optBoolean("skipPremium", true)
            
            if (activeListId.isEmpty()) return null
            
            // Get problem completion status
            val completionJson = prefs.getString("flutter.problem_completion", null)
            val completion = if (completionJson != null) org.json.JSONObject(completionJson) else org.json.JSONObject()
            
            // Get the problems from the active list
            val problems = getProblemsFromList(activeListId)
            if (problems.isEmpty()) return null
            
            // Filter based on unsolvedOnly flag
            val candidateProblems = if (unsolvedOnly) {
                problems.filter { problem ->
                    val key = "${activeListId}_${problem.id}"
                    !completion.optBoolean(key, false)
                }
            } else {
                problems
            }
            
            if (candidateProblems.isEmpty()) return null
            
            // Filter out premium problems if skipPremium is enabled
            val afterPremiumFilter = if (skipPremium) {
                candidateProblems.filter { !it.isPremium }
            } else {
                candidateProblems
            }
            
            if (afterPremiumFilter.isEmpty()) return null
            
            // Sort by difficulty if easiestFirst is enabled
            val sortedProblems = if (easiestFirst) {
                afterPremiumFilter.sortedBy { problem ->
                    when (problem.difficulty) {
                        "Easy" -> 0
                        "Medium" -> 1
                        "Hard" -> 2
                        else -> 1
                    }
                }
            } else {
                afterPremiumFilter
            }
            
            // Select problem based on random flag
            val selectedProblem = if (random) {
                if (easiestFirst && sortedProblems.isNotEmpty()) {
                    // Pick random from the easiest difficulty tier
                    val lowestDifficulty = sortedProblems.first().difficulty
                    val sameLevel = sortedProblems.filter { it.difficulty == lowestDifficulty }
                    val index = (System.currentTimeMillis() % sameLevel.size).toInt()
                    sameLevel[index]
                } else {
                    // Pick any random from candidates
                    val index = (System.currentTimeMillis() % sortedProblems.size).toInt()
                    sortedProblems[index]
                }
            } else {
                // Pick first
                sortedProblems.firstOrNull()
            }
            
            return selectedProblem?.url
        } catch (e: Exception) {
            Log.e(TAG, "Error getting next problem URL", e)
            return null
        }
    }
    
    private data class ProblemInfo(val id: String, val title: String, val url: String, val difficulty: String, val isPremium: Boolean = false)

    private fun requireMainThreadForTestApi() {
        check(Looper.myLooper() == Looper.getMainLooper()) {
            "Test accessor must be called on the main thread"
        }
    }

    // Test-only accessors/triggers
    @VisibleForTesting
    internal fun runForegroundCheckForTest(forceUpdate: Boolean = false) {
        requireMainThreadForTestApi()
        checkForegroundApp(forceUpdate)
    }

    @VisibleForTesting
    internal fun runPenaltyCheckForTest() {
        requireMainThreadForTestApi()
        checkPenaltyInBackground()
    }

    @VisibleForTesting
    internal fun runProgressCheckForTest() {
        requireMainThreadForTestApi()
        checkLeetCodeProgress()
    }

    @VisibleForTesting
    internal fun isOverlayShowingForTest(): Boolean {
        requireMainThreadForTestApi()
        return isOverlayShowing
    }

    @VisibleForTesting
    internal fun overlayRemainingTextForTest(): String? {
        requireMainThreadForTestApi()
        return remainingTextView?.text?.toString()
    }

    @VisibleForTesting
    internal fun overlayMoreTextForTest(): String? {
        requireMainThreadForTestApi()
        return moreTextView?.text?.toString()
    }

    @VisibleForTesting
    internal fun overlayStatusTextForTest(): String? {
        requireMainThreadForTestApi()
        return statusTextView?.text?.toString()
    }

    @VisibleForTesting
    internal fun overlayCheckButtonTextForTest(): String? {
        requireMainThreadForTestApi()
        return checkProgressBtn?.text?.toString()
    }

    @VisibleForTesting
    internal fun overlayCheckButtonEnabledForTest(): Boolean? {
        requireMainThreadForTestApi()
        return checkProgressBtn?.isEnabled
    }

    @VisibleForTesting
    internal fun currentlyBlockingAppForTest(): String? {
        requireMainThreadForTestApi()
        return currentlyBlockingApp
    }

    @VisibleForTesting
    internal fun getNextProblemUrlForTest(): String? {
        requireMainThreadForTestApi()
        return getNextProblemUrl()
    }
    
    private fun getProblemsFromList(listId: String): List<ProblemInfo> {
        val problems = mutableListOf<ProblemInfo>()
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        try {
            // Check if it's a default list (embedded in code) or custom list
            if (listId == "blind75" || listId == "neetcode250") {
                // For default lists, we need to read from a cached version
                // The Flutter side saves these when the app runs
                val cachedListsJson = prefs.getString("flutter.cached_default_lists", null)
                if (cachedListsJson != null) {
                    val cachedLists = org.json.JSONObject(cachedListsJson)
                    if (cachedLists.has(listId)) {
                        val listData = cachedLists.getJSONObject(listId)
                        return parseListProblems(listData)
                    }
                }
            } else {
                // Custom list - read from saved problem lists
                val listsJson = prefs.getString("flutter.problem_lists", null)
                if (listsJson != null) {
                    val listsArray = org.json.JSONArray(listsJson)
                    for (i in 0 until listsArray.length()) {
                        val listObj = listsArray.getJSONObject(i)
                        if (listObj.optString("id") == listId) {
                            return parseListProblems(listObj)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting problems from list $listId", e)
        }
        
        return problems
    }
    
    private fun parseListProblems(listObj: org.json.JSONObject): List<ProblemInfo> {
        val problems = mutableListOf<ProblemInfo>()
        try {
            if (!listObj.has("categories")) return problems
            val categories = listObj.getJSONObject("categories")
            val keys = categories.keys()
            while (keys.hasNext()) {
                val category = keys.next()
                if (!categories.has(category)) continue
                val problemsArray = categories.getJSONArray(category)
                for (i in 0 until problemsArray.length()) {
                    val problem = problemsArray.getJSONObject(i)
                    problems.add(ProblemInfo(
                        id = problem.optString("id", ""),
                        title = problem.optString("title", ""),
                        url = problem.optString("url", ""),
                        difficulty = problem.optString("difficulty", "Medium"),
                        isPremium = problem.optBoolean("isPremium", false)
                    ))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing list problems", e)
        }
        return problems
    }
    
    private fun goHome() {
        currentlyBlockingApp = null
        hideOverlay()
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
}
