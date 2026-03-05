package com.leetblock.leet_block

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServiceOverlayBehaviorTest {

    @Test
    fun blockedAppShowsOverlayWithQuotaText() {
        val nowMillis = 1772308800000L // 2026-03-01T12:00:00Z
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 4,
            completed = 1,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertTrue(service.isOverlayShowingForTest())
        assertEquals(AppBlockerServiceTestHarness.blockedPackage, service.currentlyBlockingAppForTest())
        assertEquals("3", service.overlayRemainingTextForTest())
        assertTrue(service.overlayMoreTextForTest()?.contains("left") == true)
    }

    @Test
    fun newDayRolloverImmediatelyReblocksOnFirstCheck() {
        val nowMillis = 1772308800000L // 2026-03-01T12:00:00Z
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 2, // yesterday quota met
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoForDaysAgo(1, nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        val progress = AppBlockerServiceTestHarness.readDailyProgress(service)
        assertEquals(0, progress.getInt("questionsCompletedToday"))
        val progressDate = progress.optString("date", "")
        assertTrue(
            progressDate.startsWith(AppBlockerServiceTestHarness.dateKey(nowMillis)),
        )

        assertTrue(service.isOverlayShowingForTest())
        assertEquals("2", service.overlayRemainingTextForTest())
    }
}
