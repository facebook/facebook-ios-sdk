/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import Foundation

enum TestShareUtility {
  static var stubbedValidateShareShouldThrow = false
  static var stubbedValidateNetworkURLShouldThrow = false
  static var stubbedTestShareContainsMedia = false
  static var stubbedTestShareContainsPhotos = false
  static var stubbedTestShareContainsVideos = false
  static var stubbedHashtagString: String?
  static var stubbedValidateArrayShouldThrow = false
  static var validateArrayArray: [Any]?
  static var validateArrayMinCount: Int?
  static var validateArrayMaxCount: Int?
  static var validateArrayName: String?

  static func reset() {
    stubbedValidateShareShouldThrow = false
    stubbedValidateNetworkURLShouldThrow = false
    stubbedTestShareContainsMedia = false
    stubbedTestShareContainsPhotos = false
    stubbedTestShareContainsVideos = false
    stubbedHashtagString = nil
    stubbedValidateArrayShouldThrow = false
    validateArrayArray = nil
    validateArrayMinCount = nil
    validateArrayMaxCount = nil
    validateArrayName = nil
  }
}

extension TestShareUtility: ShareUtilityProtocol {

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
}

extension TestShareUtility: ShareValidating {

  struct ValidationError: Error {}

  static func validateRequiredValue(_ value: Any, named name: String) throws {
    throw ValidationError()
  }

  static func validateArgument<Argument>(
    _ value: Argument,
    named name: String,
    in possibleValues: Set<Argument>
  ) throws where Argument: Hashable {
    throw ValidationError()
  }

  static func validateArray(_ array: [Any], minCount: Int, maxCount: Int, named name: String) throws {
    validateArrayArray = array
    validateArrayMinCount = minCount
    validateArrayMaxCount = maxCount
    validateArrayName = name

    if stubbedValidateArrayShouldThrow {
      throw ValidationError()
    }
  }

  static func validateNetworkURL(_ url: URL, named name: String) throws {
    if stubbedValidateNetworkURLShouldThrow {
      throw ValidationError()
    }
  }

  static func validateShareContent(
    _ shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions = []
  ) throws {
    if stubbedValidateShareShouldThrow {
      throw ValidationError()
    }
  }
}
