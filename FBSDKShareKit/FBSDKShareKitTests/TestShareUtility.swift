// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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
  ) {
  }

  static func buildWebShare(
    _ content: SharingContent,
    methodName methodNameRef: AutoreleasingUnsafeMutablePointer<NSString>?,
    parameters parametersRef: AutoreleasingUnsafeMutablePointer<NSDictionary>?
  ) throws {
  }

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
