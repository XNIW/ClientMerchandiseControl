import Flutter
import UIKit
import XCTest

@MainActor
private final class InspectableActivityViewController: UIActivityViewController {
  let capturedItems: [Any]
  let createdOnMainThread: Bool

  init(items: [Any]) {
    capturedItems = items
    createdOnMainThread = Thread.isMainThread
    super.init(activityItems: items, applicationActivities: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private enum NativeShareResult: Equatable {
  case completed(String?)
  case dismissed
  case busy
}

@MainActor
private final class ProductSharePresentationContract {
  private(set) var activeController: InspectableActivityViewController?
  private(set) var presentationCount = 0
  // Snapshot the pre-presentation iPad anchor: UIKit may adapt its own
  // presentation controller after the activity view controller is presented.
  private(set) var configuredSourceView: UIView?
  private(set) var configuredSourceRect = CGRect.zero
  private var completion: ((NativeShareResult) -> Void)?

  @discardableResult
  func present(
    text: String,
    publicURL: URL,
    sourceRect: CGRect,
    from host: UIViewController,
    completion: @escaping (NativeShareResult) -> Void
  ) -> NativeShareResult? {
    guard activeController == nil, host.presentedViewController == nil else {
      return .busy
    }
    precondition(Thread.isMainThread)
    precondition(text.contains(publicURL.absoluteString))

    let controller = InspectableActivityViewController(items: [text])
    controller.popoverPresentationController?.sourceView = host.view
    controller.popoverPresentationController?.sourceRect = sourceRect
    controller.popoverPresentationController?.permittedArrowDirections = .any
    configuredSourceView = controller.popoverPresentationController?.sourceView
    configuredSourceRect = controller.popoverPresentationController?.sourceRect ?? .zero
    controller.completionWithItemsHandler = { [weak self, weak host, weak controller]
      activityType, completed, _, _ in
      guard let self, self.activeController === controller else { return }
      let outcome: NativeShareResult = completed
        ? .completed(activityType?.rawValue)
        : .dismissed
      self.activeController = nil
      let callback = self.completion
      self.completion = nil
      callback?(outcome)
      if controller?.presentingViewController != nil {
        controller?.dismiss(animated: false)
      } else if host?.presentedViewController != nil {
        host?.dismiss(animated: false)
      }
    }

    activeController = controller
    self.completion = completion
    presentationCount += 1
    host.present(controller, animated: false)
    return nil
  }

  func cancel() {
    activeController?.completionWithItemsHandler?(nil, false, nil, nil)
  }

  func complete(activityType: UIActivity.ActivityType) {
    activeController?.completionWithItemsHandler?(activityType, true, nil, nil)
  }

  func applicationDidEnterBackground() {
    cancel()
  }

  func applicationDidBecomeActive() {
    precondition(Thread.isMainThread)
  }
}

@MainActor
private final class ShareHost {
  let window: UIWindow
  let viewController: UIViewController
  let originalRootViewController: UIViewController?

  init(
    window: UIWindow,
    viewController: UIViewController,
    originalRootViewController: UIViewController?
  ) {
    self.window = window
    self.viewController = viewController
    self.originalRootViewController = originalRootViewController
  }

  func close() {
    viewController.dismiss(animated: false)
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
    window.rootViewController = originalRootViewController
    window.makeKeyAndVisible()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
  }
}

@MainActor
final class RunnerTests: XCTestCase {
  private let publicURL = URL(
    string:
      "com.xniw.clientmerchandisecontrol://storefront/" +
      "storefront-test/product/50000000-0000-4000-8000-000000000001"
  )!
  private let localizedText =
    "Mira Café público en Merchandise Control:\n" +
    "com.xniw.clientmerchandisecontrol://storefront/" +
    "storefront-test/product/50000000-0000-4000-8000-000000000001"
  private let sourceRect = CGRect(x: 16, y: 16, width: 48, height: 48)

  func testPresentsRealActivityControllerWithExactPublicPayloadAndPopover() {
    let host = makeHost()
    defer { host.close() }
    let presenter = ProductSharePresentationContract()
    var result: NativeShareResult?

    XCTAssertNil(
      presenter.present(
        text: localizedText,
        publicURL: publicURL,
        sourceRect: sourceRect,
        from: host.viewController,
        completion: { result = $0 }
      )
    )

    guard let controller = presenter.activeController else {
      return XCTFail("UIActivityViewController was not created")
    }
    XCTAssertTrue(
      drainMainRunLoop(
        until: { host.viewController.presentedViewController === controller }
      ),
      "UIActivityViewController was not presented by the active host"
    )
    XCTAssertTrue(Thread.isMainThread)
    XCTAssertTrue(controller.createdOnMainThread)
    XCTAssertTrue(
      host.viewController.presentedViewController as? UIActivityViewController === controller
    )
    XCTAssertTrue(controller.presentingViewController === host.viewController)
    XCTAssertEqual(controller.capturedItems.count, 1)
    XCTAssertTrue(controller.capturedItems[0] is String)
    XCTAssertEqual(controller.capturedItems[0] as? String, localizedText)
    XCTAssertTrue(localizedText.contains(publicURL.absoluteString))
    for forbidden in [
      "source_product_id", "owner_user_id", "supplier", "cost", "token",
      "storage/", "shop_secret", "sync_metadata",
    ] {
      XCTAssertFalse(localizedText.localizedCaseInsensitiveContains(forbidden))
    }
    XCTAssertTrue(presenter.configuredSourceView === host.viewController.view)
    XCTAssertEqual(presenter.configuredSourceRect, sourceRect)
    XCTAssertFalse(presenter.configuredSourceRect.isEmpty)

    presenter.cancel()
    XCTAssertEqual(result, .dismissed)
    XCTAssertNil(presenter.activeController)
    XCTAssertTrue(
      drainMainRunLoop(until: { host.viewController.presentedViewController == nil })
    )
  }

  func testMapsCompletionAndRejectsSecondConcurrentPresentation() {
    let host = makeHost()
    defer { host.close() }
    let presenter = ProductSharePresentationContract()
    var result: NativeShareResult?

    XCTAssertNil(
      presenter.present(
        text: localizedText,
        publicURL: publicURL,
        sourceRect: sourceRect,
        from: host.viewController,
        completion: { result = $0 }
      )
    )
    let firstController = presenter.activeController

    let second = presenter.present(
      text: localizedText,
      publicURL: publicURL,
      sourceRect: sourceRect,
      from: host.viewController,
      completion: { _ in XCTFail("second presentation must not complete") }
    )
    XCTAssertEqual(second, .busy)
    XCTAssertTrue(presenter.activeController === firstController)
    XCTAssertEqual(presenter.presentationCount, 1)

    presenter.complete(activityType: .copyToPasteboard)
    XCTAssertEqual(result, .completed(UIActivity.ActivityType.copyToPasteboard.rawValue))
    XCTAssertNil(presenter.activeController)
    XCTAssertTrue(
      drainMainRunLoop(until: { host.viewController.presentedViewController == nil })
    )
  }

  func testBackgroundCancellationAllowsCleanResumePresentation() {
    let host = makeHost()
    defer { host.close() }
    let presenter = ProductSharePresentationContract()
    var results: [NativeShareResult] = []

    XCTAssertNil(
      presenter.present(
        text: localizedText,
        publicURL: publicURL,
        sourceRect: sourceRect,
        from: host.viewController,
        completion: { results.append($0) }
      )
    )
    guard let firstController = presenter.activeController else {
      return XCTFail("UIActivityViewController was not created")
    }
    XCTAssertTrue(
      drainMainRunLoop(
        until: { host.viewController.presentedViewController === firstController }
      ),
      "UIActivityViewController was not presented before backgrounding"
    )
    presenter.applicationDidEnterBackground()
    presenter.applicationDidBecomeActive()

    XCTAssertEqual(results, [.dismissed])
    XCTAssertTrue(
      drainMainRunLoop(until: { host.viewController.presentedViewController == nil })
    )
    XCTAssertNil(
      presenter.present(
        text: localizedText,
        publicURL: publicURL,
        sourceRect: sourceRect,
        from: host.viewController,
        completion: { results.append($0) }
      )
    )
    XCTAssertEqual(presenter.presentationCount, 2)
    XCTAssertNotNil(presenter.activeController)

    presenter.cancel()
    XCTAssertEqual(results, [.dismissed, .dismissed])
    XCTAssertTrue(
      drainMainRunLoop(until: { host.viewController.presentedViewController == nil })
    )
  }

  private func makeHost() -> ShareHost {
    let host = UIViewController()
    host.view.backgroundColor = .systemBackground
    guard let window = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap(\.windows)
      .first(where: { $0.isKeyWindow })
      ?? UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap(\.windows)
        .first
    else {
      fatalError("No active UIWindow is available to host UIActivityViewController")
    }
    let originalRoot = window.rootViewController
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.loadViewIfNeeded()
    host.view.layoutIfNeeded()
    _ = drainMainRunLoop(
      until: { host.view.window === window && window.isKeyWindow }
    )
    return ShareHost(
      window: window,
      viewController: host,
      originalRootViewController: originalRoot
    )
  }

  @discardableResult
  private func drainMainRunLoop(
    until condition: () -> Bool = { true },
    timeout: TimeInterval = 1
  ) -> Bool {
    let deadline = Date(timeIntervalSinceNow: timeout)
    repeat {
      if condition() { return true }
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
    } while Date() < deadline
    return condition()
  }
}
