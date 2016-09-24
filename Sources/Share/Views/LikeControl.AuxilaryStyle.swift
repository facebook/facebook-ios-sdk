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

extension LikeControl {
  /**
   Specifies the style of the auxilary view in the like control.
   */
  public enum AuxilaryStyle {
    /// Use the standard social share message.
    case standard(horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment)

    /// Use a more compact box count auxilary view.
    case boxCount(horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment)

    /// The horizontal alignment of this style.
    public var horizontalAlignment: HorizontalAlignment {
      get {
        switch self {
        case .standard(let alignment): return alignment.horizontalAlignment
        case .boxCount(let alignment): return alignment.horizontalAlignment
        }
      }
      set {
        switch self {
        case .standard(let alignment):
          self = .standard(horizontalAlignment: newValue, verticalAlignment: alignment.verticalAlignment)

        case .boxCount(let alignment):
          self = .boxCount(horizontalAlignment: newValue, verticalAlignment: alignment.verticalAlignment)
        }
      }
    }

    /// The vertical alignment of this style.
    public var verticalAlignment: VerticalAlignment {
      get {
        switch self {
        case .standard(let alignment): return alignment.verticalAlignment
        case .boxCount(let alignment): return alignment.verticalAlignment
        }
      }
      set {
        switch self {
        case .standard(let alignment):
          self = .standard(horizontalAlignment: alignment.horizontalAlignment, verticalAlignment: newValue)

        case .boxCount(let alignment):
          self = .boxCount(horizontalAlignment: alignment.horizontalAlignment, verticalAlignment: newValue)
        }
      }
    }
  }
}

extension LikeControl.AuxilaryStyle: Equatable {
  /**
   Compare two `AuxilaryStyle`'s for equality.

   - parameter lhs: The first style to compare.
   - parameter rhs: The second style to compare.

   - returns: Whether or not the styles are equal.
   */
  public static func == (lhs: LikeControl.AuxilaryStyle, rhs: LikeControl.AuxilaryStyle) -> Bool {
    switch (lhs, rhs) {
    case (.standard(let lhs), .standard(let rhs)): return lhs == rhs
    case (.boxCount(let lhs), .boxCount(let rhs)): return lhs == rhs
    default: return false
    }
  }
}

extension LikeControl.AuxilaryStyle {
  internal init(sdkStyle: FBSDKLikeControlStyle,
                sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment,
                sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition) {
    let horizontalAlignment = HorizontalAlignment(sdkHorizontalAlignment: sdkHorizontalAlignment)
    let verticalAlignment = VerticalAlignment(sdkAuxilaryPosition: sdkAuxilaryPosition)

    switch sdkStyle {
    case .standard: self = .standard(horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
    case .boxCount: self = .boxCount(horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
    }
  }

  internal var sdkStyleRepresentation: (FBSDKLikeControlStyle, FBSDKLikeControlHorizontalAlignment, FBSDKLikeControlAuxiliaryPosition) {
    switch self {
    case .standard(let horizontal, let vertical):
      return (.standard, horizontal.sdkHorizontalAlignment, vertical.sdkAuxilaryPosition)

    case .boxCount(let horizontal, let vertical):
      return (.boxCount, horizontal.sdkHorizontalAlignment, vertical.sdkAuxilaryPosition)
    }
  }
}

extension LikeControl.AuxilaryStyle {
  /**
   Control the horizontal alignment of the auxilary view.
   */
  public enum HorizontalAlignment {
    /// The auxilary view should be placed to the left of the like button.
    case left

    /// The auxilary view should be placed centered to the like button.
    case center

    /// The auxilary view should be placed to the right of the like button.
    case right

    internal init(sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment) {
      switch sdkHorizontalAlignment {
      case .left: self = .left
      case .center: self = .center
      case .right: self = .right
      }
    }

    internal var sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment {
      switch self {
      case .left: return .left
      case .center: return .center
      case .right: return .right
      }
    }
  }

  /**
   Controls vertical alignment of the auxilary view.
   */
  public enum VerticalAlignment {
    /// The auxilary view should be placed above the like button.
    case top

    /// The auxilary view should be placed inline with the like button.
    case inline

    /// The auxilary view should be placed below the like button.
    case bottom

    internal init(sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition) {
      switch sdkAuxilaryPosition {
      case .top: self = .top
      case .inline: self = .inline
      case .bottom: self = .bottom
      }
    }

    internal var sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition {
      switch self {
      case .top: return .top
      case .inline: return .inline
      case .bottom: return .bottom
      }
    }
  }
}
