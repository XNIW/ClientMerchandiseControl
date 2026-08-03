package com.xniw.clientmerchandisecontrol

import java.net.URI

internal object CustomerNotificationDeepLinkMapper {
    private const val SCHEME = "com.xniw.clientmerchandisecontrol"
    private const val HOST = "storefront"
    private val shopPattern = Regex("^[a-z0-9][a-z0-9-]{2,62}$")
    private val uuidPattern = Regex(
        "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    )

    fun canonicalDeepLink(raw: String?): String? {
        if (raw == null || raw != raw.trim()) return null
        val uri = try {
            URI(raw)
        } catch (_: Exception) {
            return null
        }
        if (
            uri.scheme != SCHEME ||
            uri.host != HOST ||
            uri.rawAuthority != HOST ||
            uri.userInfo != null ||
            uri.port != -1 ||
            uri.rawQuery != null ||
            uri.rawFragment != null
        ) {
            return null
        }
        val segments = uri.rawPath.split('/', limit = 4)
        if (
            segments.size != 4 ||
            segments[0].isNotEmpty() ||
            segments[2] != "notification"
        ) {
            return null
        }
        val shopSlug = segments[1]
        val routeToken = segments[3]
        if (!shopPattern.matches(shopSlug) || !uuidPattern.matches(routeToken)) {
            return null
        }
        val canonicalPath = "/$shopSlug/notification/$routeToken"
        if (uri.rawPath != canonicalPath || uri.toASCIIString() != raw) return null
        return raw
    }
}
