import Foundation

enum CustomerNotificationDeepLinkMapper {
  private static let scheme = "com.xniw.clientmerchandisecontrol"
  private static let host = "storefront"
  private static let shopPattern = try! NSRegularExpression(
    pattern: "^[a-z0-9][a-z0-9-]{2,62}$"
  )
  private static let uuidPattern = try! NSRegularExpression(
    pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
  )

  static func map(userInfo: [AnyHashable: Any]) -> URL? {
    if let raw = userInfo["deepLink"] as? String {
      return canonicalURL(raw)
    }
    if let data = userInfo["data"] as? [AnyHashable: Any],
      let raw = data["deepLink"] as? String
    {
      return canonicalURL(raw)
    }
    return nil
  }

  static func canonicalURL(_ raw: String) -> URL? {
    guard raw == raw.trimmingCharacters(in: .whitespacesAndNewlines),
      let components = URLComponents(string: raw),
      components.scheme == scheme,
      components.host == host,
      components.user == nil,
      components.password == nil,
      components.port == nil,
      components.query == nil,
      components.fragment == nil
    else {
      return nil
    }

    let segments = components.percentEncodedPath.split(
      separator: "/",
      omittingEmptySubsequences: false
    )
    guard segments.count == 4,
      segments[0].isEmpty,
      segments[2] == "notification"
    else {
      return nil
    }
    let shopSlug = String(segments[1])
    let routeToken = String(segments[3])
    guard matches(shopPattern, shopSlug),
      matches(uuidPattern, routeToken),
      components.percentEncodedPath == "/\(shopSlug)/notification/\(routeToken)",
      let url = components.url,
      url.absoluteString == raw
    else {
      return nil
    }
    return url
  }

  private static func matches(_ expression: NSRegularExpression, _ value: String) -> Bool {
    expression.firstMatch(
      in: value,
      range: NSRange(value.startIndex..., in: value)
    ) != nil
  }
}
