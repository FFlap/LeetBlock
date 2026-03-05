package com.leetblock.leet_block

import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServiceNextProblemSelectionTest {

    @Test
    fun getNextProblemUrlForCustomListRespectsUnsolvedAndSkipPremium() {
        val service = AppBlockerServiceTestHarness.buildService()
        val prefs = AppBlockerServiceTestHarness.prefs(service)

        val customList = JSONObject()
            .put("id", "custom")
            .put("name", "Custom")
            .put("isCustom", true)
            .put(
                "categories",
                JSONObject().put(
                    "Array",
                    JSONArray()
                        .put(
                            JSONObject()
                                .put("id", "1")
                                .put("title", "Solved")
                                .put("difficulty", "Easy")
                                .put("url", "https://leetcode.com/problems/solved/")
                                .put("isPremium", false),
                        )
                        .put(
                            JSONObject()
                                .put("id", "2")
                                .put("title", "Premium")
                                .put("difficulty", "Easy")
                                .put("url", "https://leetcode.com/problems/premium/")
                                .put("isPremium", true),
                        )
                        .put(
                            JSONObject()
                                .put("id", "3")
                                .put("title", "Candidate")
                                .put("difficulty", "Medium")
                                .put("url", "https://leetcode.com/problems/candidate/")
                                .put("isPremium", false),
                        ),
                ),
            )

        prefs.edit()
            .putString("flutter.problem_lists", JSONArray().put(customList).toString())
            .putString("flutter.problem_completion", JSONObject().put("custom_1", true).toString())
            .putString(
                "flutter.study_preferences",
                JSONObject()
                    .put("activeListId", "custom")
                    .put("random", false)
                    .put("unsolvedOnly", true)
                    .put("easiestFirst", false)
                    .put("skipPremium", true)
                    .toString(),
            )
            .commit()

        assertEquals(
            "https://leetcode.com/problems/candidate/",
            service.getNextProblemUrlForTest(),
        )
    }

    @Test
    fun getNextProblemUrlUsesCachedDefaultListWhenActiveListIsBuiltIn() {
        val service = AppBlockerServiceTestHarness.buildService()
        val prefs = AppBlockerServiceTestHarness.prefs(service)

        val cachedBlind75 = JSONObject()
            .put(
                "categories",
                JSONObject().put(
                    "Array",
                    JSONArray()
                        .put(
                            JSONObject()
                                .put("id", "1")
                                .put("title", "Two Sum")
                                .put("difficulty", "Easy")
                                .put("url", "https://leetcode.com/problems/two-sum/")
                                .put("isPremium", false),
                        )
                        .put(
                            JSONObject()
                                .put("id", "121")
                                .put("title", "Best Time to Buy and Sell Stock")
                                .put("difficulty", "Easy")
                                .put("url", "https://leetcode.com/problems/best-time-to-buy-and-sell-stock/")
                                .put("isPremium", false),
                        ),
                ),
            )

        prefs.edit()
            .putString(
                "flutter.cached_default_lists",
                JSONObject().put("blind75", cachedBlind75).toString(),
            )
            .putString("flutter.problem_completion", JSONObject().put("blind75_1", true).toString())
            .putString(
                "flutter.study_preferences",
                JSONObject()
                    .put("activeListId", "blind75")
                    .put("random", false)
                    .put("unsolvedOnly", true)
                    .put("easiestFirst", false)
                    .put("skipPremium", true)
                    .toString(),
            )
            .commit()

        assertEquals(
            "https://leetcode.com/problems/best-time-to-buy-and-sell-stock/",
            service.getNextProblemUrlForTest(),
        )
    }

    @Test
    fun getNextProblemUrlReturnsNullWhenNoStudyListSelected() {
        val service = AppBlockerServiceTestHarness.buildService()
        val prefs = AppBlockerServiceTestHarness.prefs(service)
        prefs.edit().putString("flutter.study_preferences", JSONObject().toString()).commit()

        assertNull(service.getNextProblemUrlForTest())
    }
}
