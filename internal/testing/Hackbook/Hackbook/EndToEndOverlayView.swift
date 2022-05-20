// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

@objcMembers
public final class FBEndToEndOverlayView: NSObject {

  var displayLink: CADisplayLink?
  var overlayView: FBEndToEndViewDump?
  var appWindow: UIWindow

  public init(appWindow: UIWindow) {
    self.appWindow = appWindow
  }

  public func setup() {
    ensureOverlayOnTopOfWindow()
    setupAccessibility()
  }

  // MARK: - Private

  private func ensureOverlayOnTopOfWindow() {
    displayLink = CADisplayLink(target: self, selector: #selector(bringOverlayToFrontIfNecessary))
    displayLink?.add(to: .current, forMode: .default)
  }

  @objc private func bringOverlayToFrontIfNecessary() {
    guard let overlayView = overlayView else {
      return
    }

    let rootView = self.appWindow.subviews.first
    overlayView.rootViews = NSPointerArray.weakObjects()
    rootView?.accessibilityElements = [overlayView]
    for window in UIApplication.shared.windows {
      overlayView.rootViews.addPointer(UnsafeMutableRawPointer(Unmanaged.passUnretained(window).toOpaque()))
    }
  }

  private func setupAccessibility() {
    overlayView = FBEndToEndViewDump()
    overlayView?.isAccessibilityElement = true
  }
}
