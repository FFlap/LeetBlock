package com.leetblock.leet_block

import org.json.JSONObject

data class DailyProgressSnapshot(
    val completed: Int,
    val baseQuota: Int,
    val penalty: Int,
) {
    val totalQuota: Int
        get() = baseQuota + penalty
}

data class NormalizedDailyProgress(
    val progress: JSONObject,
    val changed: Boolean,
)

object DailyProgressStore {
    fun normalize(
        current: JSONObject?,
        baseQuota: Int,
        todayKey: String,
        nowIso: String,
    ): NormalizedDailyProgress {
        val progress = if (current != null) {
            JSONObject(current.toString())
        } else {
            JSONObject()
        }
        var changed = false
        val progressDate = extractDateKey(progress.optString("date", ""))

        if (progressDate != todayKey) {
            progress.put("date", nowIso)
            progress.put("questionsCompletedToday", 0)
            progress.put("manualOffset", 0)
            progress.put("quotaPenalty", 0)
            progress.put("startOfDayTotal", 0)
            changed = true
        } else {
            val existingCompleted = progress.optInt("questionsCompletedToday", 0)
            val normalizedCompleted = existingCompleted.coerceAtLeast(0)
            if (normalizedCompleted != existingCompleted || !progress.has("questionsCompletedToday")) {
                progress.put("questionsCompletedToday", normalizedCompleted)
                changed = true
            }

            val existingPenalty = progress.optInt("quotaPenalty", 0)
            val normalizedPenalty = existingPenalty.coerceAtLeast(0)
            if (normalizedPenalty != existingPenalty || !progress.has("quotaPenalty")) {
                progress.put("quotaPenalty", normalizedPenalty)
                changed = true
            }

            if (!progress.has("manualOffset")) {
                progress.put("manualOffset", 0)
                changed = true
            }
        }

        if (!progress.has("startOfDayTotal")) {
            progress.put("startOfDayTotal", 0)
            changed = true
        }

        val safeBaseQuota = baseQuota.coerceAtLeast(0)
        if (!progress.has("dailyQuota") || progress.optInt("dailyQuota", safeBaseQuota) != safeBaseQuota) {
            progress.put("dailyQuota", safeBaseQuota)
            changed = true
        }

        return NormalizedDailyProgress(progress = progress, changed = changed)
    }

    fun snapshot(progress: JSONObject, baseQuota: Int): DailyProgressSnapshot {
        return DailyProgressSnapshot(
            completed = progress.optInt("questionsCompletedToday", 0).coerceAtLeast(0),
            baseQuota = baseQuota.coerceAtLeast(0),
            penalty = progress.optInt("quotaPenalty", 0).coerceAtLeast(0),
        )
    }

    fun mergeSubmissions(
        progress: JSONObject,
        todaySubmissions: Int,
        penalty: Int,
        baseQuota: Int,
        nowIso: String,
    ): JSONObject {
        val previousDateKey = extractDateKey(progress.optString("date", ""))
        val currentDateKey = extractDateKey(nowIso)
        val isDateTransition =
            previousDateKey == null || currentDateKey == null || previousDateKey != currentDateKey
        val manualOffset = if (isDateTransition) 0 else progress.optInt("manualOffset", 0)
        val merged = JSONObject(progress.toString())
        merged.put("questionsCompletedToday", (todaySubmissions + manualOffset).coerceAtLeast(0))
        merged.put("quotaPenalty", penalty.coerceAtLeast(0))
        merged.put("dailyQuota", baseQuota.coerceAtLeast(0))
        merged.put("date", nowIso)
        if (isDateTransition) {
            merged.put("manualOffset", 0)
            merged.put("startOfDayTotal", 0)
        } else if (!merged.has("startOfDayTotal")) {
            merged.put("startOfDayTotal", 0)
        }
        return merged
    }

    fun mergePenalty(progress: JSONObject, penalty: Int): Pair<JSONObject, Boolean> {
        val normalizedPenalty = penalty.coerceAtLeast(0)
        val currentPenalty = progress.optInt("quotaPenalty", 0).coerceAtLeast(0)
        val merged = JSONObject(progress.toString())
        if (currentPenalty == normalizedPenalty) {
            return Pair(merged, false)
        }

        merged.put("quotaPenalty", normalizedPenalty)
        return Pair(merged, true)
    }

    private fun extractDateKey(dateString: String?): String? {
        if (dateString.isNullOrBlank() || dateString.length < 10) return null
        return dateString.substring(0, 10)
    }
}
