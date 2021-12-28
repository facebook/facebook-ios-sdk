/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@testable import FBSDKCoreKit

@objcMembers
class SampleGraphRequests: NSObject {

  static let valid = create()
  static var withOutdatedVersionWithAttachment = create(
    parameters: ["attachment": Data(count: 8)],
    version: "3.0"
  )
  static var withOutdatedVersion = create(version: "3.0")
  static var withAttachment = create(parameters: ["attachment": Data(count: 8)])

  static func create(
    path: String = "/me",
    parameters: [String: Any] = [:],
    version: String = Settings.shared.graphAPIVersion
  ) -> GraphRequest {
    GraphRequest(
      graphPath: path,
      parameters: parameters,
      tokenString: nil,
      version: version,
      httpMethod: HTTPMethod.get
    )
  }
}
