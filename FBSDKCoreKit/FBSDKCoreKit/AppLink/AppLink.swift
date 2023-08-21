/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Contains App Link metadata relevant for navigation on this device
 derived from the HTML at a given URL.
 */
@objcMembers
@objc(FBSDKAppLink)
public final class AppLink: NSObject, _AppLinkProtocol {

  /// The URL from which this FBSDKAppLink was derived
  public let sourceURL: URL?

  /**
   The ordered list of targets applicable to this platform that will be used
   for navigation.
   */
  public let targets: [AppLinkTargetProtocol]

  /// The fallback web URL to use if no targets are installed on this device.
  public let webURL: URL?

  /**
   Internal property exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   > Warning: INTERNAL - DO NOT USE
   */
  public var isBackToReferrer: Bool

  /**
   Creates an AppLink with the given list of AppLinkTargets and target URL.

   Generally, this will only be used by implementers of the AppLinkResolving protocol,
   as these implementers will produce App Link metadata for a given URL.

   - Parameters:
      - sourceURL: The *URL* from which this App Link is derived.
      - targets: An ordered list of AppLinkTargets for this platform derived from App Link metadata.
      - webURL: The fallback web URL, if any, for the app link.
   */
  @objc(initWithSourceURL:targets:webURL:)
  public convenience init(sourceURL: URL?, targets: [AppLinkTargetProtocol], webURL: URL?) {
    self.init(sourceURL: sourceURL, targets: targets, webURL: webURL, isBackToReferrer: false)
  }

  /**
   Creates an AppLink with the given list of AppLinkTargets and target URL.

   Generally, this will only be used by implementers of the AppLinkResolving protocol,
   as these implementers will produce App Link metadata for a given URL.

   - Parameters:
      - sourceURL: The *URL* from which this App Link is derived.
      - targets: An ordered list of AppLinkTargets for this platform derived from App Link metadata.
      - webURL: The fallback web URL, if any, for the app link.
   */
  @available(
    *,
    deprecated,
    message: """
      Please use designated init to instantiate an AppLink. This method will be removed in future releases."
      """
  )
  @objc(appLinkWithSourceURL:targets:webURL:)
  public static func appLink(sourceURL: URL?, targets: [AppLinkTargetProtocol], webURL: URL?) -> _AppLinkProtocol {
    AppLink(sourceURL: sourceURL, targets: targets, webURL: webURL, isBackToReferrer: false)
  }

  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   > Warning: INTERNAL - DO NOT USE
   */
  @objc(initWithSourceURL:targets:webURL:isBackToReferrer:)
  public init(sourceURL: URL?, targets: [AppLinkTargetProtocol], webURL: URL?, isBackToReferrer: Bool) {
    self.sourceURL = sourceURL
    self.targets = targets
    self.webURL = webURL
    self.isBackToReferrer = isBackToReferrer
  }
}
