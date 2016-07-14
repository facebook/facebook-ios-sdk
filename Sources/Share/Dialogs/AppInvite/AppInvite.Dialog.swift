// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import Foundation
import UIKit
import FBSDKShareKit

extension AppInvite {
  /// A dialog to send app invites.
  public final class Dialog {
    private let sdkDialog: FBSDKAppInviteDialog
    private let sdkDelegate: SDKDelegate

    /// The invite to send.
    public let invite: AppInvite

    /**
     A UIViewController to present the dialog from.

     If not specified, the top most view controller will be automatically determined as best as possible.
     */
    public var presentingViewController: UIViewController? {
      get {
        return sdkDialog.fromViewController
      }
      set {
        sdkDialog.fromViewController = newValue
      }
    }

    /// The completion handler to be invoked upon showing the dialog.
    public var completion: (Result -> Void)? {
      get {
        return sdkDelegate.completion
      }
      set {
        sdkDelegate.completion = newValue
      }
    }

    /**
     Create a dialog with an invite.

     - parameter invite: The invite to send.
     */
    public init(invite: AppInvite) {
      sdkDialog = FBSDKAppInviteDialog()
      sdkDialog.content = invite.sdkInviteRepresentation

      sdkDelegate = SDKDelegate()
      sdkDelegate.setupAsDelegateFor(sdkDialog)

      self.invite = invite
    }

    /**
     Attempt to show the dialog modally.

     - throws: If the dialog fails to present.
     */
    public func show() throws {
      var error: ErrorType?
      let completionHandler = sdkDelegate.completion
      sdkDelegate.completion = {
        if case .Failed(let resultError) = $0 {
          error = resultError
        }
      }

      sdkDialog.show()
      sdkDelegate.completion = completionHandler

      if let error = error {
        throw error
      }
    }

    /**
     Validates the contents of the reciever as valid.

     - throws: If the content is invalid.
     */
    public func validate() throws {
      try sdkDialog.validate()
    }
  }
}

extension AppInvite.Dialog {
  /**
   Convenience method to show a `Dialog` with a `presentingViewController`, `invite`, and `completion`.

   - parameter viewController: The view controller to present from.
   - parameter invite:         The invite to send.
   - parameter completion:     The completion handler to invoke upon success.

   - throws: If the dialog fails to present.

   - returns: The dialog that has been presented.
   */
  public static func show(from viewController: UIViewController,
                               invite: AppInvite,
                               completion: (AppInvite.Result -> Void)? = nil) throws -> Self {
    let dialog = self.init(invite: invite)
    dialog.presentingViewController = viewController
    dialog.completion = completion
    try dialog.show()
    return dialog
  }
}
