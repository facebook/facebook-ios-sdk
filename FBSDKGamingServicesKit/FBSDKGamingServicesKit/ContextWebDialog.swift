/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit

/// A super class type for the context dialogs classes that show an in-app webview to display content.
@objcMembers
@objc(FBSDKContextWebDialog) // swiftlint:disable:next prefer_final_classes
public class ContextWebDialog: NSObject, WebDialogDelegate, DialogProtocol {

  private enum Keys {
    static var contextID = "context_id"
    static var contextSize = "context_size"
    static var errorCode = "error_code"
    static var errorMessage = "error_message"
  }

  public var delegate: ContextDialogDelegate?
  public var dialogContent: ValidatableProtocol?
  public var currentWebDialog: WebDialog?

  init(delegate: ContextDialogDelegate?, dialogContent: ValidatableProtocol?) {
    super.init()
    self.delegate = delegate
    self.dialogContent = dialogContent
  }

  public func show() -> Bool {
    false
  }

  public func validate() throws {}

  // MARK: - WebDialogDelegate

  public func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
    if currentWebDialog != webDialog {
      return
    }
    handleCompletionWithDialogResults(results)
    InternalUtility.shared.unregisterTransientObject(self)
  }

  public func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    guard let delegate = delegate, currentWebDialog == webDialog else {
      return
    }
    delegate.contextDialog(self, didFailWithError: error)
    InternalUtility.shared.unregisterTransientObject(self)
  }

  public func webDialogDidCancel(_ webDialog: WebDialog) {
    guard let delegate = delegate, currentWebDialog == webDialog else {
      return
    }
    delegate.contextDialogDidCancel(self)
    InternalUtility.shared.unregisterTransientObject(self)
  }

  /// Depending on the content size within the browser, this method allows for the resizing of web dialog
  public func createWebDialogFrame(
    withWidth width: CGFloat,
    height: CGFloat,
    windowFinder: _WindowFinding
  ) -> CGRect {
    guard let window = windowFinder.findWindow() else {
      return .zero
    }
    let windowFrame = window.frame
    let xPoint = windowFrame.width < width ? 0 : windowFrame.midX - (width / 2)
    let yPoint = windowFrame.height < height ? 0 : windowFrame.midY - (height / 2)
    let dialogWidth = windowFrame.width < width ? windowFrame.width : width
    let dialogHeight = windowFrame.height < height ? windowFrame.height : height

    return CGRect(x: xPoint, y: yPoint, width: dialogWidth, height: dialogHeight)
  }

  private func handleCompletionWithDialogResults(_ results: [String: Any]) {
    guard let delegate = delegate else {
      return
    }

    if
      let errorCode = results[Keys.errorCode] as? Int,
      let errorMessage = results[Keys.errorMessage] as? String {
      let errorFactory = ErrorFactory()
      let error = errorFactory.error(
        code: errorCode,
        userInfo: nil,
        message: errorMessage,
        underlyingError: nil
      )
      return delegate.contextDialog(self, didFailWithError: error)
    }

    if let identifier = results[Keys.contextID] as? String {
      let sizeString = results[Keys.contextSize] as? String ?? ""
      let size = Int(sizeString) ?? 0

      GamingContext.current = GamingContext(identifier: identifier, size: size)
      return delegate.contextDialogDidComplete(self)
    }

    delegate.contextDialogDidCancel(self)
  }
}
