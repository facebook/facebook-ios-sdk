/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Represents a target defined in App Link metadata, consisting of at least
 a URL, and optionally an App Store ID and name.
 */
@objcMembers
@objc(FBSDKAppLinkTarget)
public final class AppLinkTarget: NSObject, AppLinkTargetProtocol {

  /// The URL prefix for this app link target
  public let url: URL?

  /// The app ID for the app store
  public let appStoreId: String?

  /// The name of the app
  public let appName: String

  /// Creates a AppLinkTarget with the given app site and target URL.
  @objc(initWithURL:appStoreId:appName:)
  public init(url: URL?, appStoreId: String?, appName: String) {
    self.url = url
    self.appStoreId = appStoreId
    self.appName = appName
  }

  /// Creates a AppLinkTarget with the given app site and target URL.
  @available(
    *,
    deprecated,
    message: """
      Please use designated init to instantiate an AppLinkTarget. This method will be removed in future releases."
      """
  )
  @objc(appLinkTargetWithURL:appStoreId:appName:)
  public static func appLinkTargetWithURL(url: URL?, appStoreId: String?, appName: String) -> AppLinkTarget {
    AppLinkTarget(url: url, appStoreId: appStoreId, appName: appName)
  }
}
