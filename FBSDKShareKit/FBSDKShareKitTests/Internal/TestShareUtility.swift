/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import Foundation

enum TestShareUtility: ShareUtilityProtocol {

  static var stubbedValidateShareShouldThrow = false
  static var stubbedTestShareContainsMedia = false
  static var stubbedTestShareContainsPhotos = false
  static var stubbedTestShareContainsVideos = false
  static var stubbedHashtagString: String?

  static func reset() {
    stubbedValidateShareShouldThrow = false
    stubbedTestShareContainsMedia = false
    stubbedTestShareContainsPhotos = false
    stubbedTestShareContainsVideos = false
    stubbedHashtagString = nil
  }

  static func feedShareDictionary(for content: SharingContent) -> [String: Any]? {
    [:]
  }

  static func buildAsyncWebPhotoContent(
    _ content: SharePhotoContent,
    completion: WebPhotoContentHandler
  ) {}

  static func buildWebShareBridgeComponents(for content: SharingContent) -> WebShareBridgeComponents {
    WebShareBridgeComponents(methodName: "", parameters: [:])
  }

  static func hashtagString(from hashtag: Hashtag?) -> String? {
    stubbedHashtagString ?? ""
  }

  static func bridgeParameters(
    for shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions,
    shouldFailOnDataError: Bool
  ) -> [String: Any] {
    [:]
  }

  static func getContentFlags(for shareContent: SharingContent) -> ContentFlags {
    ContentFlags(
      containsMedia: stubbedTestShareContainsMedia,
      containsPhotos: stubbedTestShareContainsPhotos,
      containsVideos: stubbedTestShareContainsVideos
    )
  }

  static func shareMediaContentContainsPhotosAndVideos(_ shareMediaContent: ShareMediaContent) -> Bool {
    false
  }

  static func validateShareContent(
    _ shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions = []
  ) throws {
    if stubbedValidateShareShouldThrow {
      struct Error: Swift.Error {}
      throw Error()
    }
  }
}
