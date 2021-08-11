// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FacebookGamingServices

#if FBSDK_SWIFT_PACKAGE
import LegacyCore
#else
import FBSDKCoreKit
#endif

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
      return SDKError.error(
        withCode: CoreError.errorAccessTokenRequired.rawValue,
        message: "A valid access token is required to launch the Dialog"
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
      return SDKError.error(
        withCode: CoreError.errorAccessTokenRequired.rawValue,
        message: "A valid access token is required to launch the Dialog"
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
