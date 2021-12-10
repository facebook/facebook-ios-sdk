/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import FBSDKCoreKit

/**
  A dialog to switch the current context through a web view
 */
@objcMembers
open class FBSDKSwitchContextDialog: NSObject, WebDialogDelegate, DialogProtocol, Showable {

  let dialog: SwitchContextDialogProtocol

  init(dialog: SwitchContextDialogProtocol) {
    self.dialog = dialog
  }

  /**
   Builds a switch context web dialog with content and a delegate.

   - Parameters:
    - content: The content for the switch context dialog
    - windowFinder: The application window finder that provides the window to display the dialog
    - delegate: The receiver's delegate used to let the receiver know if a context switch was successful
   */
  public static func dialog(
    withContent content: SwitchContextContent,
    windowFinder: WindowFinding,
    delegate: ContextDialogDelegate
  ) -> FBSDKSwitchContextDialog {
    let dialog = SwitchContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )

    return FBSDKSwitchContextDialog(dialog: dialog)
  }

  // MARK: - WebDialogDelegate

  public func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
    dialog.webDialog(webDialog, didCompleteWithResults: results)
  }

  public func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    dialog.webDialog(webDialog, didFailWithError: error)
  }

  public func webDialogDidCancel(_ webDialog: WebDialog) {
    dialog.webDialogDidCancel(webDialog)
  }

  // MARK: - DialogProtocol

  public var delegate: ContextDialogDelegate? {
    get {
      dialog.delegate
    }
    set {
      dialog.delegate = newValue
    }
  }

  public var dialogContent: ValidatableProtocol? {
    get {
      dialog.dialogContent
    }
    set {
      dialog.dialogContent = newValue
    }
  }

  public func show() -> Bool {
    dialog.show()
  }

  public func validate() throws {
    try dialog.validate()
  }

  // MARK: - ContextWebDialog Subclass Methods

  public var currentWebDialog: WebDialog? {
    get {
      dialog.currentWebDialog
    }
    set {
      dialog.currentWebDialog = newValue
    }
  }

  public func createWebDialogFrame(
    width: CGFloat,
    height: CGFloat,
    windowFinder: WindowFinding
  ) -> CGRect {
    dialog.createWebDialogFrame(
      withWidth: width,
      height: height,
      windowFinder: windowFinder
    )
  }
}
