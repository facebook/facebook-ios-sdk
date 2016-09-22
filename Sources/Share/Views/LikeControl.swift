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

/**
 UI control to like an object in the Facebook graph.

 Taps on the like button within this control will invoke an API call to the Facebook app through a fast-app-switch
 that allows the user to like the object. Upon return to the calling app, the view will update with the new state.
 */
public class LikeControl: UIView {
  fileprivate let sdkLikeControl: FBSDKLikeControl

  /**
   Create a new LikeControl with an optional frame and object.

   - parameter frame:  The frame to use for this control. If `nil`, defaults to a default size.
   - parameter object: The object to like.
   */
  public init(frame: CGRect? = nil, object: LikableObject) {
    let sdkLikeControl = FBSDKLikeControl()
    let frame = frame ?? sdkLikeControl.bounds

    self.sdkLikeControl = sdkLikeControl

    super.init(frame: frame)

    self.object = object
    addSubview(sdkLikeControl)
  }

  /**
   Create a new LikeControl from an encoded interface file.

   - parameter coder: The coder to initialize from.
   */
  public required init?(coder: NSCoder) {
    sdkLikeControl = FBSDKLikeControl()

    super.init(coder: coder)
    self.addSubview(sdkLikeControl)
  }

  /// The foreground color to use for the content of the control.
  public var foregroundColor: UIColor {
    get {
      return sdkLikeControl.foregroundColor
    }
    set {
      sdkLikeControl.foregroundColor = newValue
    }
  }

  /// The object to like.
  public var object: LikableObject {
    get {
      return LikableObject(sdkObjectType: sdkLikeControl.objectType, sdkObjectId: sdkLikeControl.objectID)
    }
    set {
      let sdkRepresentation = newValue.sdkObjectRepresntation
      sdkLikeControl.objectType = sdkRepresentation.objectType
      sdkLikeControl.objectID = sdkRepresentation.objectId
    }
  }

  /// The style to use for this control.
  public var auxilaryStyle: AuxilaryStyle {
    get {
      return AuxilaryStyle(
        sdkStyle: sdkLikeControl.likeControlStyle,
        sdkHorizontalAlignment: sdkLikeControl.likeControlHorizontalAlignment,
        sdkAuxilaryPosition: sdkLikeControl.likeControlAuxiliaryPosition
      )
    }
    set {
      (
        sdkLikeControl.likeControlStyle,
        sdkLikeControl.likeControlHorizontalAlignment,
        sdkLikeControl.likeControlAuxiliaryPosition
      ) = newValue.sdkStyleRepresentation
    }
  }

  /**
   The preferred maximum width (in points) for autolayout.

   This property affects the size of the receiver when layout constraints are applied to it. During layout,
   if the text extends beyond the width specified by this property, the additional text is flowed to one or more new
   lines, thereby increasing the height of the receiver.
   */
  public var preferredMaxLayoutWidth: CGFloat {
    get {
      return sdkLikeControl.preferredMaxLayoutWidth
    }
    set {
      sdkLikeControl.preferredMaxLayoutWidth = newValue
    }
  }

  /// If `true`, a sound is played when the control is toggled.
  public var isSoundEnabled: Bool {
    get {
      return sdkLikeControl.isSoundEnabled
    }
    set {
      sdkLikeControl.isSoundEnabled = newValue
    }
  }
}

extension LikeControl {
  /**
   Performs logic for laying out subviews.
   */
  public override func layoutSubviews() {
    super.layoutSubviews()

    sdkLikeControl.frame = CGRect(origin: .zero, size: bounds.size)
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
    return sdkLikeControl.sizeThatFits(size)
  }

  /**
   Returns the natural size for the receiving view, considering only properties of the view itself.

   - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
   */
  public override var intrinsicContentSize: CGSize {
    return sdkLikeControl.intrinsicContentSize
  }
}
