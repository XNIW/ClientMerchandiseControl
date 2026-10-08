package com.xniw.clientmerchandisecontrol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AddressCreationDurabilityTest {
    @Test
    fun waitsForKeyAndConfigurationBeforeCommittingPayload() {
        val committed = mutableListOf<String>()
        assertTrue(AddressCreationDurability.flush {
            committed.add(it)
            true
        })
        assertEquals(listOf(
            "FlutterSecureKeyStorage:cmc_address_creation_v1",
            "FlutterSecureStorageConfiguration:cmc_address_creation_v1",
            "cmc_address_creation_v1",
        ), committed)
    }

    @Test
    fun neverAcknowledgesAnyFailedCommit() {
        for (failedIndex in 0..2) {
            var attempts = 0
            assertFalse(AddressCreationDurability.flush {
                attempts++ != failedIndex
            })
            assertEquals(failedIndex + 1, attempts)
        }
    }

    @Test(expected = IllegalStateException::class)
    fun exceptionCannotBecomeSuccessfulAcknowledgement() {
        AddressCreationDurability.flush { throw IllegalStateException() }
    }
}
