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
import java.time.Duration

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServiceProgressCheckTest {

    @Test
    fun simulatedCompletionUpdatesQuotaAndHidesOverlayWhenMet() {
        val nowMillis = 1772308800000L // 2026-03-01T12:00:00Z
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.usageSnapshotProvider = { UsageSnapshot(totalBlockedTimeMs = 0L, perAppTimeMs = emptyMap()) }

        var fetchCalls = 0
        service.todaySubmissionsFetcher = { username ->
            fetchCalls++
            assertEquals("offline-tester", username)
            2
        }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.runProgressCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        val progress = AppBlockerServiceTestHarness.readDailyProgress(service)
        assertEquals(2, progress.getInt("questionsCompletedToday"))
        assertEquals(0, progress.getInt("quotaPenalty"))
        assertEquals(1, fetchCalls)
        assertTrue(service.overlayStatusTextForTest()?.contains("Quota met! Unlocking...") == true)

        AppBlockerServiceTestHarness.advanceMainLooper(Duration.ofMillis(1100))
        AppBlockerServiceTestHarness.idleMainLooper()

        assertFalse(service.isOverlayShowingForTest())
        assertNull(service.currentlyBlockingAppForTest())
    }

    @Test
    fun progressCheckShowsNoUsernameErrorWhenUsernameMissing() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            username = null,
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.runProgressCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertEquals("No username configured", service.overlayStatusTextForTest())
        assertEquals("Check Progress", service.overlayCheckButtonTextForTest())
        assertEquals(true, service.overlayCheckButtonEnabledForTest())
    }

    @Test
    fun progressCheckFailureRestoresButtonAndShowsError() {
        val nowMillis = 1772308800000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 2,
            completed = 0,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = false,
        )

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.todaySubmissionsFetcher = { _ -> -1 }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.runProgressCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        assertEquals("Failed to fetch. Try again.", service.overlayStatusTextForTest())
        assertEquals("Check Progress", service.overlayCheckButtonTextForTest())
        assertEquals(true, service.overlayCheckButtonEnabledForTest())
        assertTrue(service.isOverlayShowingForTest())
    }
}
