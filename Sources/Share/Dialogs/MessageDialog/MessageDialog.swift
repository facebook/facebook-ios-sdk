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

/// A dialog for sharing content through Messenger.
public final class MessageDialog<Content: ContentProtocol> {

  fileprivate let sdkSharer: FBSDKMessageDialog
  fileprivate let sdkShareDelegate: SDKSharingDelegateBridge<Content>

  /**
   Create a `MessageDialog` with a given content.

   - parameter content: The content to share.
   */
  public init(content: Content) {
    sdkSharer = FBSDKMessageDialog()
    sdkShareDelegate = SDKSharingDelegateBridge<Content>()

    sdkShareDelegate.setupAsDelegateFor(sdkSharer)
    sdkSharer.shareContent = ContentBridger.bridgeToObjC(content)
  }
}

extension MessageDialog: ContentSharingProtocol {

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
  public var completion: ((ContentSharerResult<Content>) -> Void)? {
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

extension MessageDialog: ContentSharingDialogProtocol {
  /**
   Shows the dialog.

   - throws: If the dialog cannot be presented.
   */
  public func show() throws {
    var error: Error?
    let completionHandler = sdkShareDelegate.completion
    sdkShareDelegate.completion = {
      if case .failed(let resultError) = $0 {
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

extension MessageDialog {
  /**
   Convenience method to show a Message Share Dialog with content and a completion handler.

   - parameter content:    The content to share.
   - parameter completion: The completion handler to invoke.

   - returns: The dialog that has been presented.
   - throws: If the dialog fails to validate.
   */
  @discardableResult
  public static func show(_ content: Content, completion: ((ContentSharerResult<Content>) -> Void)? = nil) throws -> Self {
    let dialog = self.init(content: content)
    dialog.completion = completion
    try dialog.show()
    return dialog
  }
}
