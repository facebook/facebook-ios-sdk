/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */

@objcMembers
@objc(FBSDKWebDialog)
public final class _WebDialog: NSObject {
  public var shouldDeferVisibility = false
  public weak var delegate: WebDialogDelegate?
  var name: String
  var webViewFrame: CGRect
  var parameters: [String: String]?
  var backgroundView: UIView?
  var dialogView: FBWebDialogView?

  private enum AnimationDuration {
    static let show = 0.2
    static let dismiss = 0.3
  }

  private enum URLParameterKeys {
    static let display = "display"
    static let sdk = "sdk"
    static let redirectURI = "redirect_uri"
    static let appID = "app_id"
    static let accessToken = "access_token"
  }

  private enum URLParameterValues {
    static let touch = "touch"
    static let sdkVersion = "ios-\(Settings.shared.sdkVersion)"
    static let success = "fbconnect://success"
  }

  public init(
    name: String,
    parameters: [String: String]?,
    webViewFrame: CGRect = .zero
  ) {
    self.name = name
    self.parameters = parameters
    self.webViewFrame = webViewFrame
  }

  public convenience init(name: String) {
    self.init(name: name, parameters: nil, webViewFrame: .zero)
  }

  public func show() {
    do {
      let url = try generateURL()
      guard (try? Self.getDependencies().windowFinder.findWindow()) != nil else {
        _Logger.singleShotLogEntry(
          .developerErrors,
          logEntry: "There are no valid windows in which to present this web dialog"
        )
        let error = try Self.getDependencies().errorFactory.unknownError(
          message: "There are no valid windows in which to present this web dialog"
        )
        fail(with: error)
        return
      }

      let frame = webViewFrame.isEmpty ? applicationFrameForOrientation() : webViewFrame
      dialogView = FBWebDialogView(frame: frame)
      dialogView?.delegate = self
      dialogView?.load(url)

      if !shouldDeferVisibility {
        showWebView()
      }
    } catch {
      fail(with: error)
    }
  }

  func addObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(deviceOrientationDidChangeNotification(_:)),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }

  func deviceOrientationDidChangeNotification(_ notification: Notification) {
    if let animated = notification.userInfo?["UIDeviceOrientationRotateAnimatedUserInfoKey"] as? Bool {
      let animationDuration = animated ? CATransaction.animationDuration() : 0
      updateView(scale: 1.0, alpha: 1.0, animationDuration: animationDuration) { finished in
        if finished {
          self.dialogView?.setNeedsLayout()
        }
      }
    }
  }

  func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
  }

  func cancel() {
    delegate?.webDialogDidCancel(self)
    dismiss(animated: true)
  }

  func complete(with results: [String: Any]) {
    delegate?.webDialog(self, didCompleteWithResults: results)
    dismiss(animated: true)
  }

  func dismiss(animated: Bool) {
    removeObservers()

    let didDismiss: (Bool) -> Void = { _ in
      self.backgroundView?.removeFromSuperview()
      self.dialogView?.removeFromSuperview()
    }

    if animated {
      UIView.animate(
        withDuration: 0.3,
        animations: {
          self.dialogView?.alpha = 0.0
          self.backgroundView?.alpha = 0.0
        },
        completion: didDismiss
      )
    } else {
      didDismiss(true)
    }
  }

  func fail(with error: Error) {
    delegate?.webDialog(self, didFailWithError: error)
    dismiss(animated: true)
  }

  func generateURL() throws -> URL {
    var urlParameters = [String: String]()
    urlParameters[URLParameterKeys.display] = URLParameterValues.touch
    urlParameters[URLParameterKeys.sdk] = URLParameterValues.sdkVersion
    urlParameters[URLParameterKeys.redirectURI] = URLParameterValues.success
    urlParameters[URLParameterKeys.appID] = Settings.shared.appID
    urlParameters[URLParameterKeys.accessToken] = AccessToken.current?.tokenString

    if let parameters = parameters {
      urlParameters = parameters.merging(urlParameters) { _, last in last }
    }
    return try InternalUtility.shared.facebookURL(
      withHostPrefix: "m",
      path: "/dialog/\(name)",
      queryParameters: urlParameters
    )
  }

  func showWebView() {
    guard let window = try? Self.getDependencies().windowFinder.findWindow() else {
      let message = "There are no valid windows in which to present this web dialog"
      _Logger.singleShotLogEntry(
        LoggingBehavior.developerErrors, logEntry: message
      )
      if let error = try? Self.getDependencies().errorFactory.unknownError(
        message: message
      ) {
        fail(with: error)
      }
      return
    }

    addObservers()
    backgroundView = UIView(frame: window.bounds)
    backgroundView?.alpha = 0
    backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backgroundView?.backgroundColor = UIColor(white: 0.3, alpha: 0.8)

    guard let dialogView = dialogView,
          let backgroundView = backgroundView
    else {
      let message = "dialog or background view has not been created or set"
      _Logger.singleShotLogEntry(
        LoggingBehavior.developerErrors, logEntry: message
      )
      if let error = try? Self.getDependencies().errorFactory.unknownError(
        message: message
      ) {
        fail(with: error)
      }
      return
    }

    window.addSubview(backgroundView)
    window.addSubview(dialogView)
    dialogView.becomeFirstResponder()

    updateView(scale: 0.001, alpha: 0.0, animationDuration: 0.0)
    updateView(scale: 1.1, alpha: 1.0, animationDuration: AnimationDuration.show) { _ in
      self.updateView(scale: 0.9, alpha: 1.0, animationDuration: AnimationDuration.show) { _ in
        self.updateView(scale: 1.0, alpha: 1.0, animationDuration: AnimationDuration.show)
      }
    }
  }

  func applicationFrameForOrientation() -> CGRect {
    var applicationFrame = dialogView?.window?.screen.bounds
    guard var insets = dialogView?.window?.safeAreaInsets else {
      return .zero
    }

    if insets.top == 0 {
      insets.top = UIApplication.shared.statusBarFrame.size.height
    }

    applicationFrame?.origin.x += insets.left
    applicationFrame?.origin.y += insets.top
    applicationFrame?.size.width -= insets.left + insets.right
    applicationFrame?.size.height -= insets.top + insets.bottom
    return applicationFrame ?? .zero
  }

  func updateView(
    scale: CGFloat,
    alpha: CGFloat,
    animationDuration: TimeInterval,
    completion: ((Bool) -> Void)? = nil
  ) {
    let transform = dialogView?.transform
    let applicationFrame = webViewFrame.isEmpty ? applicationFrameForOrientation() : webViewFrame
    if scale == 1 {
      dialogView?.transform = .identity
      dialogView?.frame = applicationFrame
      dialogView?.transform = transform ?? .identity
    }

    let updateBlock = { [self] in
      dialogView?.transform = transform ?? .identity
      dialogView?.center = CGPoint(x: applicationFrame.midX, y: applicationFrame.midY)
      dialogView?.alpha = alpha
      backgroundView?.alpha = alpha
    }

    if animationDuration == 0 {
      updateBlock()
    } else {
      UIView.animate(withDuration: animationDuration, animations: updateBlock, completion: completion)
    }
  }
}

// MARK: - WebDialogViewDelegate

extension _WebDialog: WebDialogViewDelegate {

  public func webDialogView(_ webDialogView: FBWebDialogView, didCompleteWithResults results: [String: Any]) {
    complete(with: results)
  }

  public func webDialogView(_ webDialogView: FBWebDialogView, didFailWithError error: Error) {
    fail(with: error)
  }

  public func webDialogViewDidCancel(_ webDialogView: FBWebDialogView) {
    cancel()
  }

  public func webDialogViewDidFinishLoad(_ webDialogView: FBWebDialogView) {
    if shouldDeferVisibility {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        if self.dialogView != nil {
          self.showWebView()
        }
      }
    }
  }
}

extension _WebDialog: DependentAsType {
  struct TypeDependencies {
    var errorFactory: ErrorCreating
    var windowFinder: _WindowFinding
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    errorFactory: ErrorFactory(reporter: ErrorReporter.shared),
    windowFinder: InternalUtility.shared
  )
}

#endif
