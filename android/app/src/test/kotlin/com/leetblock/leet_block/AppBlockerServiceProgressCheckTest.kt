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
        AppBlockerServiceTestHarness.prefs(service).edit()
            .putString(
                "flutter.cached_default_lists",
                org.json.JSONObject()
                    .put(
                        "blind75",
                        org.json.JSONObject().put(
                            "categories",
                            org.json.JSONObject().put(
                                "Array",
                                org.json.JSONArray()
                                    .put(
                                        org.json.JSONObject()
                                            .put("id", "1")
                                            .put("title", "Two Sum")
                                            .put("difficulty", "Easy")
                                            .put("url", "https://leetcode.com/problems/two-sum/")
                                            .put("isPremium", false),
                                    )
                                    .put(
                                        org.json.JSONObject()
                                            .put("id", "121")
                                            .put("title", "Best Time to Buy and Sell Stock")
                                            .put("difficulty", "Easy")
                                            .put("url", "https://leetcode.com/problems/best-time-to-buy-and-sell-stock/")
                                            .put("isPremium", false),
                                    ),
                            ),
                        ),
                    )
                    .toString(),
            )
            .putString(
                "flutter.study_preferences",
                org.json.JSONObject()
                    .put("activeListId", "blind75")
                    .put("random", false)
                    .put("unsolvedOnly", true)
                    .put("easiestFirst", false)
                    .put("skipPremium", true)
                    .toString(),
            )
            .commit()

        service.nowMillisProvider = { nowMillis }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }
        service.usageSnapshotProvider = { UsageSnapshot(totalBlockedTimeMs = 0L, perAppTimeMs = emptyMap()) }

        var fetchCalls = 0
        service.acceptedSubmissionFetcher = { username ->
            fetchCalls++
            assertEquals("offline-tester", username)
            AcceptedSubmissionSnapshot(
                todayCount = 2,
                recentAcceptedTitles = setOf("Two Sum"),
            )
        }

        service.runForegroundCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()
        assertTrue(service.isOverlayShowingForTest())

        service.runProgressCheckForTest()
        AppBlockerServiceTestHarness.idleMainLooper()

        val progress = AppBlockerServiceTestHarness.readDailyProgress(service)
        val completion = AppBlockerServiceTestHarness.readProblemCompletion(service)
        assertEquals(2, progress.getInt("questionsCompletedToday"))
        assertEquals(0, progress.getInt("quotaPenalty"))
        assertTrue(completion.optBoolean("blind75_1"))
        assertEquals(
            "https://leetcode.com/problems/best-time-to-buy-and-sell-stock/",
            service.getNextProblemUrlForTest(),
        )
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
        service.acceptedSubmissionFetcher = {
            AcceptedSubmissionSnapshot(
                todayCount = -1,
                recentAcceptedTitles = emptySet(),
            )
        }

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
