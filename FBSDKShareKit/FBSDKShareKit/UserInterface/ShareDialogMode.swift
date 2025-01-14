/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension ShareDialog {
  /**
   Modes for the FBSDKShareDialog.

   The automatic mode will progressively check the availability of different modes and open the most
   appropriate mode for the dialog that is available.
   */
  @objc(FBSDKShareDialogMode)
  public enum Mode: UInt, CustomStringConvertible {
    /// Acts with the most appropriate mode that is available.
    case automatic

    /// Displays the dialog in the main native Facebook app.
    case native

    /// Displays the dialog in the iOS integrated share sheet.
    case shareSheet

    /// Displays the dialog in Safari.
    case browser

    /// Displays the dialog in a WKWebView within the app.
    @available(
      *,
      deprecated,
      message: "The web sharing mode is deprecated. Consider using automatic sharing mode instead."
    )
    case web

    /// Displays the feed dialog in Safari.
    @available(
      *,
      deprecated,
      message: "The feed browser sharing mode is deprecated. Consider using automatic or browser sharing modes instead."
    )
    case feedBrowser

    /// Displays the feed dialog in a WKWebView within the app.
    @available(
      *,
      deprecated,
      message: "The feed web sharing mode is deprecated. Consider using automatic sharing mode instead."
    )
    case feedWeb

    /// The string description
    public var description: String {
      switch self {
      case .automatic: return "Automatic"
      case .native: return "Native"
      case .shareSheet: return "ShareSheet"
      case .browser: return "Browser"
      case .web: return "Web"
      case .feedBrowser: return "FeedBrowser"
      case .feedWeb: return "FeedWeb"
      }
    }
  }
}
