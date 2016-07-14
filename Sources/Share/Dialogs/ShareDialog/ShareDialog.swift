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

import FBSDKShareKit

/// A dialog for sharing content on Facebook.
public final class ShareDialog<Content: ContentProtocol> {
  private let sdkSharer: FBSDKShareDialog
  private let sdkShareDelegate: SDKSharingDelegateBridge<Content>

  /**
   A `UIViewController` to present the dialog from.

   If not specified, the top most view controller will be automatically determined as best as possible.
   */
  public var presentingViewController: UIViewController? {
    get {
      return sdkSharer.fromViewController
    }
    set {
      sdkSharer.fromViewController = newValue
    }
  }

  /**
   The mode with which to display the dialog.

   Defaults to `.Automatic`, which will automatically choose the best available mode.
   */
  public var mode: ShareDialogMode {
    get {
      return ShareDialogMode(sdkShareMode: sdkSharer.mode)
    }
    set {
      sdkSharer.mode = newValue.sdkShareMode
    }
  }

  /**
   Create a `ShareDialog` with a given content.

   - parameter content: The content to share.
   */
  public init(content: Content) {
    sdkSharer = FBSDKShareDialog()
    sdkShareDelegate = SDKSharingDelegateBridge<Content>()

    sdkShareDelegate.setupAsDelegateFor(sdkSharer)
    sdkSharer.shareContent = ContentBridger.bridgeToObjC(content)
  }
}

extension ShareDialog: ContentSharingProtocol {

  /// The content that is being shared.
  public var content: Content {
    get {
      guard let swiftContent: Content = ContentBridger.bridgeToSwift(sdkSharer.shareContent) else {
        fatalError("Content of our private share dialog has changed type. Something horrible has happened.")
      }
      return swiftContent
    }
  }

  /// The completion handler to be invoked upon the share performing.
  public var completion: (ContentSharerResult<Content> -> Void)? {
    get {
      return sdkShareDelegate.completion
    }
    set {
      sdkShareDelegate.completion = newValue
    }
  }

  /// Whether or not this sharer fails on invalid data.
  public var failsOnInvalidData: Bool {
    get {
      return sdkSharer.shouldFailOnDataError
    }
    set {
      sdkSharer.shouldFailOnDataError = newValue
    }
  }

  /**
   Validates the content on the receiver.
   - throws: If The content could not be validated.
   */
  public func validate() throws {
    try sdkSharer.validate()
  }
}


extension ShareDialog: ContentSharingDialogProtocol {
  /**
   Shows the dialog.

   - throws: If the dialog cannot be presented.
   */
  public func show() throws {
    var error: ErrorType?
    let completionHandler = sdkShareDelegate.completion
    sdkShareDelegate.completion = {
      if case .Failed(let resultError) = $0 {
        error = resultError
      }
    }

    sdkSharer.show()
    sdkShareDelegate.completion = completionHandler

    if let error = error {
      throw error
    }
  }
}

extension ShareDialog {
  /**
   Convenience method to create and show a `ShareDialog` with a `fromViewController`, `content`, and `completion`.

   - parameter viewController: The viewController to present the dialog from.
   - parameter content:        The content to share.
   - parameter completion:     The completion handler to invoke.

   - returns: The `ShareDialog` that has been presented.
   - throws: If the dialog fails to validate.
   */
  public static func show(from viewController: UIViewController,
                               content: Content,
                               completion: (ContentSharerResult<Content> -> Void)? = nil) throws -> Self {
    let shareDialog = self.init(content: content)
    shareDialog.presentingViewController = viewController
    shareDialog.completion = completion
    try shareDialog.show()
    return shareDialog
  }
}
