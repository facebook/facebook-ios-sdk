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

import Foundation

import FBSDKCoreKit

/**
  A dialog to switch the current gaming context through a web view
 */
public class SwitchContextDialog: ContextWebDialog, Showable {

  enum Keys {
    static let contextID = "context_id"
  }

  enum DialogFrame {
    static let width: CGFloat = 300.0
    static let height: CGFloat = 170.0
  }

  let windowFinder: WindowFinding
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
    windowFinder: WindowFinding,
    delegate: ContextDialogDelegate
  ) {
    self.windowFinder = windowFinder

    super.init(delegate: delegate)
    dialogContent = content
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
      "context",
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
