package com.leetblock.leet_block

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PenaltyProgressMergeTest {

    @Test
    fun mergePenaltyUpdatesOnlyPenaltyField() {
        val progress = JSONObject(
            mapOf(
                "questionsCompletedToday" to 6,
                "manualOffset" to 3,
                "quotaPenalty" to 1,
                "dailyQuota" to 4,
            ),
        )

        val (merged, changed) = DailyProgressStore.mergePenalty(progress, penalty = 5)

        assertTrue(changed)
        assertEquals(6, merged.getInt("questionsCompletedToday"))
        assertEquals(3, merged.getInt("manualOffset"))
        assertEquals(4, merged.getInt("dailyQuota"))
        assertEquals(5, merged.getInt("quotaPenalty"))
    }
}
