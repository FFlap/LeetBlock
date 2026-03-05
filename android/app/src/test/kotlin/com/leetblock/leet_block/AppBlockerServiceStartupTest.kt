package com.leetblock.leet_block

import android.app.Service
import android.content.Intent
import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.TIRAMISU])
class AppBlockerServiceStartupTest {

    @Test
    fun onStartCommandStopsWhenPermissionsMissing() {
        val service = AppBlockerServiceTestHarness.buildService()
        service.overlayPermissionChecker = { false }

        val result = service.onStartCommand(Intent(), 0, 1)

        assertEquals(Service.START_NOT_STICKY, result)
        assertFalse(service.isOverlayShowingForTest())
    }

    @Test
    fun onStartCommandStartsLoopWhenPermissionsGranted() {
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
        service.overlayPermissionChecker = { true }
        service.foregroundAppResolver = { AppBlockerServiceTestHarness.blockedPackage }

        val result = service.onStartCommand(Intent(), 0, 1)
        AppBlockerServiceTestHarness.idleMainLooper()

        assertEquals(Service.START_STICKY, result)
        assertTrue(service.isOverlayShowingForTest())
    }
}
