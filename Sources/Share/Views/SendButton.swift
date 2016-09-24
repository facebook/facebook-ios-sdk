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
import FBSDKShareKit

/**
 A button for sending content with messenger.
 */
public class SendButton<C: ContentProtocol>: UIView {
  fileprivate var sdkSendButton: FBSDKSendButton

  /// The content to share.
  public var content: C? = nil {
    didSet {
      sdkSendButton.shareContent = content.flatMap(ContentBridger.bridgeToObjC)
    }
  }

  /**
   Create a new SendButton with a given frame and content.

   - parameter frame:   The frame to initialize with.
   - parameter content: The content to share.
   */
  public init(frame: CGRect? = nil, content: C? = nil) {
    let sdkSendButton = FBSDKSendButton()
    let frame = frame ?? sdkSendButton.bounds

    self.sdkSendButton = sdkSendButton
    self.content = content

    super.init(frame: frame)
    addSubview(sdkSendButton)
  }

  required public init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  /**
   Performs logic for laying out subviews.
   */
  public override func layoutSubviews() {
    super.layoutSubviews()

    sdkSendButton.frame = CGRect(origin: .zero, size: bounds.size)
  }

  /**
   Resizes and moves the receiver view so it just encloses its subviews.
   */
  public override func sizeToFit() {
    bounds.size = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
  }

  /**
   Asks the view to calculate and return the size that best fits the specified size.

   - parameter size: A new size that fits the receiver’s subviews.

   - returns: A new size that fits the receiver’s subviews.
   */
  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    return sdkSendButton.sizeThatFits(size)
  }

  /**
   Returns the natural size for the receiving view, considering only properties of the view itself.

   - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
   */
  public override var intrinsicContentSize: CGSize {
    return sdkSendButton.intrinsicContentSize
  }
}
