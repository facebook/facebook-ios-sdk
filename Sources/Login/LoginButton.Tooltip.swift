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
import FBSDKLoginKit

extension LoginButton {
  /**
   Indicates the desired login tooltip behavior.
   */
  public enum TooltipBehavior {
    /// Tooltip will only be displayed if the app is eligible (determined by possible server round trip).
    case automatic
    /// Force display of the tooltip (typically for UI testing).
    case forceDisplay
    /// Force disable the tooltip.
    case disable

    internal var sdkBehavior: FBSDKLoginButtonTooltipBehavior {
      switch self {
      case .automatic: return .automatic
      case .forceDisplay: return .forceDisplay
      case .disable: return .disable
      }
    }
  }
}

extension LoginButton {
  /**
   Indicates the desired login tooltip color style.
   */
  public enum TooltipColorStyle {
    /// Light blue background, white text, faded blue close button.
    case friendlyBlue
    /// Dark gray background, white text, light gray close button.
    case neutralGray

    internal var sdkColorStyle: FBSDKTooltipColorStyle {
      switch self {
      case .friendlyBlue: return .friendlyBlue
      case .neutralGray: return .neutralGray
      }
    }
  }
}
