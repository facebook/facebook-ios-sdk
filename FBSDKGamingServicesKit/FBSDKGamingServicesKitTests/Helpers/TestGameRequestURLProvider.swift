/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import Foundation

final class TestGameRequestURLProvider: GameRequestURLProviding {
  static var stubbedDeepLinkURL: URL?

  static func createDeepLinkURL(queryDictionary: [String: Any]) -> URL? {
    stubbedDeepLinkURL
  }

  static func filtersName(for filters: GameRequestFilter) -> String? {
    nil
  }

  static func actionTypeName(for actionType: GameRequestActionType) -> String? {
    nil
  }

  static func reset() {
    stubbedDeepLinkURL = nil
  }
}
