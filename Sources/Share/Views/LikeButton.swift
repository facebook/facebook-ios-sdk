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
import Foundation

/**
 A button to like an object.

 Tapping the receiver will invoke an API call to the Facebook app through a fast-app-switch that allows
 the object to be liked.  Upon return to the calling app, the view will update with the new state.  If the
 currentAccessToken has "publish_actions" permission and the object is an Open Graph object, then the like can happen
 seamlessly without the fast-app-switch.
 */

@available(*, deprecated, message: "FBSDKLikeButton is deprecated")
public class LikeButton: UIView {

  private var sdkLikeButton: FBSDKLikeButton

  /// If `true`, a sound is played when the reciever is toggled.
  public var isSoundEnabled: Bool {
    get {
      return sdkLikeButton.isSoundEnabled
    }
    set {
      sdkLikeButton.isSoundEnabled = newValue
    }
  }

  /// The object to like
  public var object: LikableObject {
    get {
      return LikableObject(sdkObjectType: sdkLikeButton.objectType, sdkObjectId: sdkLikeButton.objectID)
    }
    set {
      let sdkRepresentation = newValue.sdkObjectRepresntation
      sdkLikeButton.objectType = sdkRepresentation.objectType
      sdkLikeButton.objectID = sdkRepresentation.objectId
    }
  }

  /**
   Create a new LikeButton with a given frame and object.

   - parameter frame: The frame to initialize with.
   - parameter object: The object to like.
   */
  public init(frame: CGRect? = nil, object: LikableObject) {
    let sdkLikeButton = FBSDKLikeButton()
    let frame = frame ?? sdkLikeButton.bounds

    self.sdkLikeButton = sdkLikeButton

    super.init(frame: frame)

    self.object = object
    self.addSubview(sdkLikeButton)
  }

  /**
   Create a new LikeButton from an encoded interface file.

   - parameter aDecoder: The coder to initialize from.
   */
  public required init?(coder aDecoder: NSCoder) {
    sdkLikeButton = FBSDKLikeButton()

    super.init(coder: aDecoder)
    addSubview(sdkLikeButton)
  }

  /**
   Performs logic for laying out subviews.
   */
  override public func layoutSubviews() {
    super.layoutSubviews()

    sdkLikeButton.frame = CGRect(origin: .zero, size: bounds.size)
  }

  /**
   Resizes and moves the receiver view so it just encloses its subviews.
   */
  override public func sizeToFit() {
    bounds.size = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
  }

  /**
   Asks the view to calculate and return the size that best fits the specified size.

   - parameter size: A new size that fits the receiver’s subviews.

   - returns: A new size that fits the receiver’s subviews.
   */
  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return sdkLikeButton.sizeThatFits(size)
  }

  /**
   Returns the natural size for the receiving view, considering only properties of the view itself.

   - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
   */
  override public var intrinsicContentSize: CGSize {
    return sdkLikeButton.intrinsicContentSize
  }
}
