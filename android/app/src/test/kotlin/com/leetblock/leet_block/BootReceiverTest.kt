package com.leetblock.leet_block

import android.content.Intent
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BootReceiverTest {

    @Test
    fun serviceStartsOnlyForBootWhenSetupIsComplete() {
        assertTrue(shouldStartBlockerService(Intent.ACTION_BOOT_COMPLETED, isSetupComplete = true))
        assertFalse(shouldStartBlockerService(Intent.ACTION_BOOT_COMPLETED, isSetupComplete = false))
        assertFalse(shouldStartBlockerService(Intent.ACTION_AIRPLANE_MODE_CHANGED, isSetupComplete = true))
        assertFalse(shouldStartBlockerService(null, isSetupComplete = true))
    }
}
