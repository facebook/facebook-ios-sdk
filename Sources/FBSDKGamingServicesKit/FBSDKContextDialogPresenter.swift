/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookGamingServices
import FBSDKCoreKit

@objcMembers
open class FBSDKContextDialogPresenter: NSObject {

  /**
   Convenience method to build up an instant games create context dialog with content and delegate.

      - Parameters:
         - content: The content for the create context dialog
         - delegate: The receiver's delegate.
      */
  public class func createContextDialog(
    withContent content: CreateContextContent,
    delegate: ContextDialogDelegate?
  ) -> CreateContextDialog? {
    guard let delegate = delegate else {
      return nil
    }

    return CreateContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  /**
   Convenience method to build up and show an instant games create context dialog with content and delegate.

   - Parameters:
      - content: The content for the create context dialog
      - delegate: The receiver's delegate.
   */
  public class func showCreateContextDialog(
    withContent content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) -> NSError? {
    do {
      try ContextDialogPresenter().makeAndShowCreateContextDialog(
        content: content,
        delegate: delegate
      )
      return nil
    } catch {
      return ErrorFactory().error(
        code: CoreError.errorAccessTokenRequired.rawValue,
        userInfo: nil,
        message: "A valid access token is required to launch the Dialog",
        underlyingError: nil
      ) as NSError
    }
  }

  /**
   Convenience method to build up an instant games switch context dialog with content and delegate.

   - Parameters:
      - content: The content for the switch context dialog
      - delegate: The receiver's delegate.
   */
  public class func switchContextDialog(
    withContent content: SwitchContextContent,
    delegate: ContextDialogDelegate?
  ) -> SwitchContextDialog? {
    guard
      let delegate = delegate,
      AccessToken.current != nil
    else {
      return nil
    }

    return SwitchContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  /**
   Convenience method to build up and show an instant games switch context dialog with content and delegate.

   - Parameters:
      - content: The content for the switch context dialog
      - delegate: The receiver's delegate.
   */
  public class func showSwitchContextDialog(
    withContent content: SwitchContextContent,
    delegate: ContextDialogDelegate?
  ) -> NSError? {
    guard
      let delegate = delegate,
      AccessToken.current != nil
    else {
      return nil
    }

    do {
      try ContextDialogPresenter().makeAndShowSwitchContextDialog(
        content: content,
        delegate: delegate
      )
      return nil
    } catch {
      return ErrorFactory().error(
        code: CoreError.errorAccessTokenRequired.rawValue,
        userInfo: nil,
        message: "A valid access token is required to launch the Dialog",
        underlyingError: nil
      ) as NSError
    }
  }

  /**
   Convenience method to build up and show an instant games choose context dialog with content and a delegate.

   - Parameters:
      - content: The content for the choose context dialog
      - delegate: The receiver's delegate.
   */
  @discardableResult
  public class func showChooseContextDialog(
    withContent content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog {
    let dialog = ChooseContextDialog(content: content, delegate: delegate)
    dialog.show()

    return dialog
  }
}
