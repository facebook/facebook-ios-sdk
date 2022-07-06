/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol GameRequestURLProviding {
  static func createDeepLinkURL(queryDictionary: [String: Any]) -> URL?
  static func filtersName(for filters: GameRequestFilter) -> String?
  static func actionTypeName(for actionType: GameRequestActionType) -> String?
}

extension GameRequestURLProvider: GameRequestURLProviding {}
