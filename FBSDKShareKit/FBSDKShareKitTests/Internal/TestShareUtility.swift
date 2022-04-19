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
  static func reset() {
    resetContentFlagValues()
    resetHashtagValues()

    resetRequiredValueValues()
    resetValidateArgumentValues()
    resetValidateArrayValues()
    resetValidateNetworkURLValues()
    resetValidateShareContentValues()
  }
}

extension TestShareUtility: ShareUtilityProtocol {

  static func feedShareDictionary(for content: SharingContent) -> [String: Any]? {
    [:]
  }

  static var capturedAsyncWebPhotoContentContent: SharePhotoContent?
  static var capturedAsyncWebPhotoContentCompletion: WebPhotoContentHandler?

  static func buildAsyncWebPhotoContent(
    _ content: SharePhotoContent,
    completion: @escaping WebPhotoContentHandler
  ) {
    capturedAsyncWebPhotoContentContent = content
    capturedAsyncWebPhotoContentCompletion = completion
  }

  static var stubbedWebShareBridgeComponents: WebShareBridgeComponents?
  static var capturedWebShareBridgeComponentsContent: SharingContent?

  static func buildWebShareBridgeComponents(for content: SharingContent) -> WebShareBridgeComponents {
    guard let components = stubbedWebShareBridgeComponents else {
      fatalError("Missing stubbed components")
    }

    capturedWebShareBridgeComponentsContent = content
    return components
  }

  static func bridgeParameters(
    for shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions,
    shouldFailOnDataError: Bool
  ) -> [String: Any] {
    [:]
  }

  static func shareMediaContentContainsPhotosAndVideos(_ shareMediaContent: ShareMediaContent) -> Bool {
    false
  }

  // MARK: Content flags

  static var stubbedTestShareContainsMedia = false
  static var stubbedTestShareContainsPhotos = false
  static var stubbedTestShareContainsVideos = false

  static func getContentFlags(for shareContent: SharingContent) -> ContentFlags {
    ContentFlags(
      containsMedia: stubbedTestShareContainsMedia,
      containsPhotos: stubbedTestShareContainsPhotos,
      containsVideos: stubbedTestShareContainsVideos
    )
  }

  static func resetContentFlagValues() {
    stubbedTestShareContainsMedia = false
    stubbedTestShareContainsPhotos = false
    stubbedTestShareContainsVideos = false
  }

  // MARK: Hashtags

  static var stubbedHashtagString: String?

  static func hashtagString(from hashtag: Hashtag?) -> String? {
    stubbedHashtagString ?? ""
  }

  static func resetHashtagValues() {
    stubbedHashtagString = nil
  }
}

extension TestShareUtility: ShareValidating {

  struct ValidationError: Error {}

  // MARK: Validate required value

  static var validateRequiredValueShouldThrow = false
  static var validateRequiredValueValue: Any?
  static var validateRequiredValueName: String?

  static func validateRequiredValue(_ value: Any, named name: String) throws {
    validateRequiredValueValue = value
    validateRequiredValueName = name

    if validateRequiredValueShouldThrow {
      throw ValidationError()
    }
  }

  static func resetRequiredValueValues() {
    validateRequiredValueShouldThrow = false
    validateRequiredValueValue = nil
    validateRequiredValueName = nil
  }

  // MARK: Validate argument

  static var validateArgumentShouldThrow = false

  static func validateArgument<Argument>(
    _ value: Argument,
    named name: String,
    in possibleValues: Set<Argument>
  ) throws where Argument: Hashable {
    if validateArgumentShouldThrow {
      throw ValidationError()
    }
  }

  static func resetValidateArgumentValues() {
    validateArgumentShouldThrow = false
  }

  // MARK: Validate array

  static var validateArrayShouldThrow = false
  static var validateArrayArray: [Any]?
  static var validateArrayMinCount: Int?
  static var validateArrayMaxCount: Int?
  static var validateArrayName: String?

  static func validateArray(_ array: [Any], minCount: Int, maxCount: Int, named name: String) throws {
    validateArrayArray = array
    validateArrayMinCount = minCount
    validateArrayMaxCount = maxCount
    validateArrayName = name

    if validateArrayShouldThrow {
      throw ValidationError()
    }
  }

  static func resetValidateArrayValues() {
    validateArrayShouldThrow = false
    validateArrayArray = nil
    validateArrayMinCount = nil
    validateArrayMaxCount = nil
    validateArrayName = nil
  }

  // MARK: Validate network URL

  static var validateNetworkURLShouldThrow = false

  static func validateNetworkURL(_ url: URL, named name: String) throws {
    if validateNetworkURLShouldThrow {
      throw ValidationError()
    }
  }

  static func resetValidateNetworkURLValues() {
    validateNetworkURLShouldThrow = false
  }

  // MARK: Validate share content

  static var validateShareContentShouldThrow = false

  static func validateShareContent(
    _ shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions = []
  ) throws {
    if validateShareContentShouldThrow {
      throw ValidationError()
    }
  }

  static func resetValidateShareContentValues() {
    validateShareContentShouldThrow = false
  }
}
