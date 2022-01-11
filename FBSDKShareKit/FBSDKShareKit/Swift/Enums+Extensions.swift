/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 ShareDialog.Mode CustomStringConvertible
 */
@available(tvOS, unavailable)
extension ShareDialog.Mode: CustomStringConvertible {
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
    default: return "Unknown"
    }
  }
}

/**
 AppGroupPrivacy CustomStringConvertible
 */
@available(tvOS, unavailable)
extension AppGroupPrivacy: CustomStringConvertible {
  /// The string description
  public var description: String {
    __NSStringFromFBSDKAppGroupPrivacy(self)
  }
}
