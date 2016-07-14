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

/**
 Modes for the `ShareDialog`.

 The automatic mode will progressively check the availability of different modes and open the most appropriate mode
 for the dialog that is available.
 */
public enum ShareDialogMode {
  /// Acts with the most appropriate mode that is available.
  case Automatic

  /// Displays the dialog in the main native Facebook app.
  case Native

  /// Displays the dialog in the iOS integrated share sheet.
  case ShareSheet

  /// Displays the dialog in Safari.
  case Browser

  /// Displays the dialog in a UIWebView within the app.
  case Web

  /// Displays the feed dialog in Safari.
  case FeedBrowser

  /// Displays the feed dialog in a UIWebView within the app.
  case FeedWeb
}

extension ShareDialogMode {
  internal init(sdkShareMode: FBSDKShareDialogMode) {
    switch sdkShareMode {
    case .Automatic:   self = .Automatic
    case .Native:      self = .Native
    case .ShareSheet:  self = .ShareSheet
    case .Browser:     self = .Browser
    case .Web:         self = .Web
    case .FeedBrowser: self = .FeedBrowser
    case .FeedWeb:     self = .FeedWeb
    }
  }

  internal var sdkShareMode: FBSDKShareDialogMode {
    switch self {
    case .Automatic: return .Automatic
    case .Native: return .Native
    case .ShareSheet: return .ShareSheet
    case .Browser: return .Browser
    case .Web: return .Web
    case .FeedBrowser: return .FeedBrowser
    case .FeedWeb: return .FeedWeb
    }
  }
}
