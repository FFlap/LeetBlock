package com.leetblock.leet_block

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DailyProgressStoreTest {

    @Test
    fun normalizeResetsOldDayAndMaintainsQuotaShape() {
        val current = JSONObject(
            mapOf(
                "date" to "2026-02-27T08:00:00.000",
                "questionsCompletedToday" to 5,
                "manualOffset" to 2,
                "quotaPenalty" to 3,
            ),
        )

        val normalized = DailyProgressStore.normalize(
            current = current,
            baseQuota = 4,
            todayKey = "2026-02-28",
            nowIso = "2026-02-28T09:00:00.000",
        )

        assertTrue(normalized.changed)
        assertEquals("2026-02-28T09:00:00.000", normalized.progress.getString("date"))
        assertEquals(0, normalized.progress.getInt("questionsCompletedToday"))
        assertEquals(0, normalized.progress.getInt("manualOffset"))
        assertEquals(0, normalized.progress.getInt("quotaPenalty"))
        assertEquals(4, normalized.progress.getInt("dailyQuota"))
        assertEquals(0, normalized.progress.getInt("startOfDayTotal"))
    }

    @Test
    fun snapshotComputesTotalQuotaFromPenalty() {
        val progress = JSONObject(
            mapOf(
                "questionsCompletedToday" to 3,
                "quotaPenalty" to 2,
            ),
        )

        val snapshot = DailyProgressStore.snapshot(progress, baseQuota = 4)

        assertEquals(3, snapshot.completed)
        assertEquals(4, snapshot.baseQuota)
        assertEquals(2, snapshot.penalty)
        assertEquals(6, snapshot.totalQuota)
    }

    @Test
    fun mergeSubmissionsPreservesManualOffsetAndUpdatesCounts() {
        val progress = JSONObject(
            mapOf(
                "date" to "2026-02-28T08:00:00.000",
                "questionsCompletedToday" to 1,
                "manualOffset" to 2,
                "quotaPenalty" to 0,
                "dailyQuota" to 2,
            ),
        )

        val merged = DailyProgressStore.mergeSubmissions(
            progress = progress,
            todaySubmissions = 3,
            penalty = 1,
            baseQuota = 4,
            nowIso = "2026-02-28T10:00:00.000",
        )

        assertEquals(5, merged.getInt("questionsCompletedToday"))
        assertEquals(2, merged.getInt("manualOffset"))
        assertEquals(1, merged.getInt("quotaPenalty"))
        assertEquals(4, merged.getInt("dailyQuota"))
        assertEquals("2026-02-28T10:00:00.000", merged.getString("date"))
    }

    @Test
    fun mergePenaltyNoopWhenValueUnchanged() {
        val progress = JSONObject(
            mapOf(
                "questionsCompletedToday" to 4,
                "manualOffset" to 1,
                "quotaPenalty" to 2,
            ),
        )

        val (_, changed) = DailyProgressStore.mergePenalty(progress, penalty = 2)
        assertFalse(changed)
    }
}
