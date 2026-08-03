package com.xniw.clientmerchandisecontrol

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CustomerNotificationDeepLinkMapperTest {
    private val route =
        "com.xniw.clientmerchandisecontrol://storefront/" +
            "storefront-test/notification/f1000000-0000-4000-8000-000000031001"

    @Test
    fun acceptsOnlyCanonicalOpaqueNotificationRoute() {
        assertEquals(route, CustomerNotificationDeepLinkMapper.canonicalDeepLink(route))

        listOf(
            null,
            " $route",
            "$route?orderId=88000000-0000-4000-8000-000000028101",
            "$route#fragment",
            route.replace("f1000000", "F1000000"),
            route.replace("/notification/", "/order/"),
            route.replace("storefront-test", "../inventory"),
            route.replace("//storefront/", "//owner@storefront/"),
            "https://example.invalid/storefront-test/notification/" +
                "f1000000-0000-4000-8000-000000031001",
        ).forEach { candidate ->
            assertNull(candidate, CustomerNotificationDeepLinkMapper.canonicalDeepLink(candidate))
        }
    }
}
