/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

final class TestGamingUtility: GamingUtility {
  static var stubbedGraphDomain: String?

  static func getGraphDomainFromToken() -> String? { stubbedGraphDomain }

  static func reset() {
    stubbedGraphDomain = nil
  }
}
