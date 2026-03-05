package com.leetblock.leet_block

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServiceTransitionsTest {

    @Test
    fun strictModeBlocksOwnAppWhenQuotaNotMet() {
        val nowMillis = 1772308800000L // 2026-03-01T12:00:00Z
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            strictMode = true,
            blockedApps = emptySet(),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { service.packageName }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertTrue(service.isOverlayShowingForTest())
        assertEquals(service.packageName, service.currentlyBlockingAppForTest())
    }

    @Test
    fun safeAppHidesOverlayWhenBlockingActive() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.foregroundAppResolver = { "com.android.settings" }
        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertFalse(service.isOverlayShowingForTest())
        assertNull(service.currentlyBlockingAppForTest())
    }

    @Test
    fun nonBlockedNonSafeAppHidesOverlayWhenBlockingActive() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.foregroundAppResolver = { "com.example.unblocked" }
        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertFalse(service.isOverlayShowingForTest())
        assertNull(service.currentlyBlockingAppForTest())
    }

    @Test
    fun launcherForegroundKeepsOverlayVisible() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.foregroundAppResolver = { "com.android.launcher3" }
        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertTrue(service.isOverlayShowingForTest())
        assertEquals(AppBlockerServiceTestHarness.blockedPackage, service.currentlyBlockingAppForTest())
    }

    @Test
    fun penaltyChangeForcesForegroundRecheckAndShowsOverlay() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 1,
            completed = 1, // initially quota met
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = true,
            penaltyThresholdMins = 10,
            penaltyIncrement = 1,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.usageSnapshotProvider = {
            UsageSnapshot(
                totalBlockedTimeMs = 10 * 60 * 1000L,
                perAppTimeMs = mapOf(AppBlockerServiceTestHarness.blockedPackage to 10 * 60 * 1000L),
            )
        }

        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        val progress = AppBlockerServiceTestHarness.readDailyProgress(service)
        assertEquals(1, progress.getInt("quotaPenalty"))
        assertTrue(service.isOverlayShowingForTest())
        assertEquals("1", service.overlayRemainingTextForTest())
    }
}
