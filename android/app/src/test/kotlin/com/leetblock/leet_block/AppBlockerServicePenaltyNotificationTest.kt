package com.leetblock.leet_block

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServicePenaltyNotificationTest {

    @Test
    fun penaltyWarningEmitsAtThresholdAndDoesNotRefireInSameCycle() {
        val nowMillis = 1772308800000L // 2026-03-01T12:00:00Z
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 3,
            completed = 1,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(nowMillis),
            penaltyEnabled = true,
            penaltyThresholdMins = 10,
            penaltyIncrement = 1,
        )

        service.nowMillisProvider = { nowMillis }
        service.usageSnapshotProvider = {
            UsageSnapshot(
                totalBlockedTimeMs = 9 * 60 * 1000L,
                perAppTimeMs = mapOf(AppBlockerServiceTestHarness.blockedPackage to 9 * 60 * 1000L),
            )
        }

        var warningCalls = 0
        service.penaltyWarningObserver = { warningCalls++ }

        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        val manager = service.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val allNotifications = shadowOf(manager).allNotifications
        val warningNotifications =
            allNotifications.filter {
                it.extras?.getString(Notification.EXTRA_TITLE) == "Penalty Warning"
            }

        assertFalse(warningNotifications.isEmpty())
        assertEquals(1, warningCalls)
        val warningText = warningNotifications.last().extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        assertTrue(warningText?.contains("left until penalty") == true)

        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertEquals(1, warningCalls)
    }

    @Test
    fun longThresholdWarningAndNextDayResetRefires() {
        val day1 = 1772308800000L // 2026-03-01T12:00:00Z
        val day2 = day1 + 24L * 60L * 60L * 1000L
        val service = AppBlockerServiceTestHarness.buildService()
        AppBlockerServiceTestHarness.seedPrefs(
            service = service,
            dailyQuota = 3,
            completed = 0,
            penalty = 0,
            dateIso = AppBlockerServiceTestHarness.isoNow(day1),
            penaltyEnabled = true,
            penaltyThresholdMins = 20,
            penaltyIncrement = 1,
        )

        var now = day1
        service.nowMillisProvider = { now }
        service.usageSnapshotProvider = {
            UsageSnapshot(
                totalBlockedTimeMs = 18 * 60 * 1000L,
                perAppTimeMs = mapOf(AppBlockerServiceTestHarness.blockedPackage to 18 * 60 * 1000L),
            )
        }

        var warningCalls = 0
        service.penaltyWarningObserver = { warningCalls++ }

        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertEquals(1, warningCalls)

        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertEquals(1, warningCalls)

        now = day2
        service.runPenaltyCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertEquals(2, warningCalls)
    }
}
