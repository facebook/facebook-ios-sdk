/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
final class TestShareUtility: NSObject, ShareUtilityProtocol {
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
    completionHandler completion: WebPhotoContentBlock
  ) {}

  static func buildWebShare(
    _ content: SharingContent,
    methodName methodNameRef: AutoreleasingUnsafeMutablePointer<NSString>?,
    parameters parametersRef: AutoreleasingUnsafeMutablePointer<NSDictionary>?
  ) throws {}

  static func hashtagString(from hashtag: Hashtag?) -> String? {
    stubbedHashtagString ?? ""
  }

  static func parameters(
    forShare shareContent: SharingContent,
    bridgeOptions: ShareBridgeOptions = [],
    shouldFailOnDataError: Bool
  ) -> [String: Any] {
    [:]
  }

  static func testShare(
    _ shareContent: SharingContent,
    containsMedia containsMediaRef: UnsafeMutablePointer<ObjCBool>?,
    containsPhotos containsPhotosRef: UnsafeMutablePointer<ObjCBool>,
    containsVideos containsVideosRef: UnsafeMutablePointer<ObjCBool>
  ) {
    containsMediaRef?.pointee = ObjCBool(stubbedTestShareContainsMedia)
    containsPhotosRef.pointee = ObjCBool(stubbedTestShareContainsPhotos)
    containsVideosRef.pointee = ObjCBool(stubbedTestShareContainsVideos)
  }

  static func shareMediaContentContainsPhotosAndVideos(_ shareMediaContent: ShareMediaContent) -> Bool {
    false
  }

  static func validateShare(
    _ shareContent: SharingContent,
    bridgeOptions: ShareBridgeOptions = []
  ) throws {
    if stubbedValidateShareShouldThrow {
      struct Error: Swift.Error {}
      throw Error()
    }
  }
}
