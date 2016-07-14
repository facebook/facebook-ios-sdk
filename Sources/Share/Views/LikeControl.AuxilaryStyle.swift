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
  public enum AuxilaryStyle: Equatable {
    /// Use the standard social share message.
    case Standard(horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment)

    /// Use a more compact box count auxilary view.
    case BoxCount(horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment)

    /// The horizontal alignment of this style.
    public var horizontalAlignment: HorizontalAlignment {
      get {
        switch self {
        case .Standard(let alignment): return alignment.horizontalAlignment
        case .BoxCount(let alignment): return alignment.horizontalAlignment
        }
      }
      set {
        switch self {
        case .Standard(let alignment):
          self = .Standard(horizontalAlignment: newValue, verticalAlignment: alignment.verticalAlignment)

        case .BoxCount(let alignment):
          self = .BoxCount(horizontalAlignment: newValue, verticalAlignment: alignment.verticalAlignment)
        }
      }
    }

    /// The vertical alignment of this style.
    public var verticalAlignment: VerticalAlignment {
      get {
        switch self {
        case .Standard(let alignment): return alignment.verticalAlignment
        case .BoxCount(let alignment): return alignment.verticalAlignment
        }
      }
      set {
        switch self {
        case .Standard(let alignment):
          self = .Standard(horizontalAlignment: alignment.horizontalAlignment, verticalAlignment: newValue)

        case .BoxCount(let alignment):
          self = .BoxCount(horizontalAlignment: alignment.horizontalAlignment, verticalAlignment: newValue)
        }
      }
    }
  }
}

extension LikeControl.AuxilaryStyle {
  internal init(
    sdkStyle: FBSDKLikeControlStyle,
    sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment,
    sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition
    ) {
    let horizontalAlignment = HorizontalAlignment(sdkHorizontalAlignment: sdkHorizontalAlignment)
    let verticalAlignment = VerticalAlignment(sdkAuxilaryPosition: sdkAuxilaryPosition)

    switch sdkStyle {
    case .Standard: self = .Standard(horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
    case .BoxCount: self = .BoxCount(horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
    }
  }

  internal var sdkStyleRepresentation: (FBSDKLikeControlStyle, FBSDKLikeControlHorizontalAlignment, FBSDKLikeControlAuxiliaryPosition) {
    switch self {
    case .Standard(let horizontal, let vertical):
      return (.Standard, horizontal.sdkHorizontalAlignment, vertical.sdkAuxilaryPosition)

    case .BoxCount(let horizontal, let vertical):
      return (.BoxCount, horizontal.sdkHorizontalAlignment, vertical.sdkAuxilaryPosition)
    }
  }
}

extension LikeControl.AuxilaryStyle {
  /**
   Control the horizontal alignment of the auxilary view.
   */
  public enum HorizontalAlignment {
    /// The auxilary view should be placed to the left of the like button.
    case Left

    /// The auxilary view should be placed centered to the like button.
    case Center

    /// The auxilary view should be placed to the right of the like button.
    case Right

    internal init(sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment) {
      switch sdkHorizontalAlignment {
      case .Left: self = .Left
      case .Center: self = .Center
      case .Right: self = .Right
      }
    }

    internal var sdkHorizontalAlignment: FBSDKLikeControlHorizontalAlignment {
      switch self {
      case .Left: return .Left
      case .Center: return .Center
      case .Right: return .Right
      }
    }
  }

  /**
   Controls vertical alignment of the auxilary view.
   */
  public enum VerticalAlignment {
    /// The auxilary view should be placed above the like button.
    case Top

    /// The auxilary view should be placed inline with the like button.
    case Inline

    /// The auxilary view should be placed below the like button.
    case Bottom

    internal init(sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition) {
      switch sdkAuxilaryPosition {
      case .Top: self = .Top
      case .Inline: self = .Inline
      case .Bottom: self = .Bottom
      }
    }

    internal var sdkAuxilaryPosition: FBSDKLikeControlAuxiliaryPosition {
      switch self {
      case .Top: return .Top
      case .Inline: return .Inline
      case .Bottom: return .Bottom
      }
    }
  }
}

/**
 Compare two `AuxilaryStyle`'s for equality.

 - parameter lhs: The first style to compare.
 - parameter rhs: The second style to compare.

 - returns: Whether or not the styles are equal.
 */
public func == (lhs: LikeControl.AuxilaryStyle, rhs: LikeControl.AuxilaryStyle) -> Bool {
  switch (lhs, rhs) {
  case (.Standard(let lhs), .Standard(let rhs)): return lhs == rhs
  case (.BoxCount(let lhs), .BoxCount(let rhs)): return lhs == rhs
  default: return false
  }
}
