/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit

/// A dialog to switch the current gaming context through a web view
public final class SwitchContextDialog: ContextWebDialog, Showable {

  enum Keys {
    static let contextID = "context_id"
  }

  enum DialogFrame {
    static let width: CGFloat = 300.0
    static let height: CGFloat = 185.0
  }

  let windowFinder: _WindowFinding
  var frame: CGRect {
    createWebDialogFrame(
      withWidth: DialogFrame.width,
      height: DialogFrame.height,
      windowFinder: windowFinder
    )
  }

  /**
   Creates a switch context web dialog with content and a delegate.

   - Parameter content: The content for the switch context dialog
   - Parameter windowFinder: The application window finder that provides the window to display the dialog
   - Parameter delegate: The receiver's delegate used to let the receiver know a context switch was successful or failed
   */
  public init(
    content: SwitchContextContent,
    windowFinder: _WindowFinding,
    delegate: ContextDialogDelegate
  ) {
    self.windowFinder = windowFinder
    super.init(delegate: delegate, dialogContent: content)
  }

  public override func show() -> Bool {
    do {
      try validate()
    } catch {
      delegate?.contextDialog(self, didFailWithError: error)
      return false
    }

    guard let content = dialogContent as? SwitchContextContent else {
      delegate?.contextDialog(
        self,
        didFailWithError: GamingServicesDialogError.invalidContentType
      )
      return false
    }

    currentWebDialog = WebDialog.createAndShow(
      name: "context",
      parameters: [Keys.contextID: content.contextTokenID],
      frame: frame,
      delegate: self,
      windowFinder: windowFinder
    )

    InternalUtility.shared.registerTransientObject(self)

    return true
  }

  public override func validate() throws {
    guard let content = dialogContent else {
      throw GamingServicesDialogError.missingContent
    }

    try content.validate()
  }
}
