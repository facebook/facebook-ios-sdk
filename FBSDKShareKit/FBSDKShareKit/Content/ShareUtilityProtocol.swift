/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol ShareUtilityProtocol {

  static func feedShareDictionary(for content: SharingContent) -> [String: Any]?

  typealias WebPhotoContentHandler = (Bool, String, [String: Any]) -> Void

  static func buildAsyncWebPhotoContent(
    _ content: SharePhotoContent,
    completion: @escaping WebPhotoContentHandler
  )

  static func buildWebShareBridgeComponents(for content: SharingContent) -> WebShareBridgeComponents

  static func hashtagString(from hashtag: Hashtag?) -> String?

  static func bridgeParameters(
    for shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions,
    shouldFailOnDataError: Bool
  ) -> [String: Any]

  static func getContentFlags(for shareContent: SharingContent) -> ContentFlags

  static func shareMediaContentContainsPhotosAndVideos(_ shareMediaContent: ShareMediaContent) -> Bool
}

struct WebShareBridgeComponents {
  var methodName: String
  var parameters: [String: Any]

  init(methodName: String, parameters: [String: Any]) {
    self.methodName = methodName
    self.parameters = parameters
  }
}
