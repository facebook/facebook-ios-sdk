/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

/// A dialog to create a context through a web view
@objcMembers
@objc(FBSDKCreateContextDialog)
public final class CreateContextDialog: ContextWebDialog {

  private enum Keys {
    static let methodName = "context"
  }

  private enum DialogFrame {
    static let width: CGFloat = 300.0
    static let height: CGFloat = 185.0
  }

  let windowFinder: _WindowFinding

  /**
   Builds a context creation web dialog with content and a delegate.
   @param content The content for the create context dialog
   @param windowFinder The application window finder that provides the window to display the dialog
   @param delegate The receiver's delegate used to let the receiver know a context was created or failure
   */
  public init(
    content: CreateContextContent,
    windowFinder: _WindowFinding,
    delegate: ContextDialogDelegate
  ) {
    self.windowFinder = windowFinder
    super.init(delegate: delegate, dialogContent: content)
  }

  @discardableResult public override func show() -> Bool {
    do {
      try validate()
    } catch {
      delegate?.contextDialog(self, didFailWithError: error)
      return false
    }

    guard let dialogContent = dialogContent as? CreateContextContent else {
      return false
    }

    var parameters: [String: Any] = [:]
    if !dialogContent.playerID.isEmpty {
      parameters["player_id"] = dialogContent.playerID
    }

    let frame = createWebDialogFrame(
      withWidth: DialogFrame.width,
      height: DialogFrame.height,
      windowFinder: windowFinder
    )

    currentWebDialog = WebDialog.createAndShow(
      name: Keys.methodName,
      parameters: parameters,
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

#endif
