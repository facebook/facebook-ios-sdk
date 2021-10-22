/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

@objcMembers
class SampleRawRemotePermissionList: NSObject {

  static var missingPermissions: [String: Any] {
    [
      "data": [
        [
          "permission": nil,
          "status": "granted"
        ],
        [
          "permission": nil,
          "status": "declined"
        ],
        [
          "permission": nil,
          "status": "expired"
        ]
      ]
    ]
  }

  static var missingStatus: [String: Any] {
    [
      "data": [
        [
          "permission": "email",
          "status": nil
        ]
      ]
    ]
  }

  static let missingTopLevelKey: [String: Any] = [:]

  static var randomValues: Any {
    let json: Any = [
      "data": [
        [
          "permission": "foo",
          "status": "granted"
        ]
      ]
    ]
    return Fuzzer.randomize(json: json)
  }

  static var validAllStatuses: [String: Any] {
    [
      "data": [
        [
          "permission": "email",
          "status": "granted"
        ],
        [
          "permission": "birthday",
          "status": "declined"
        ],
        [
          "permission": "first_name",
          "status": "expired"
        ]
      ]
    ]
  }

  static func with(
    granted: [String] = [],
    declined: [String] = [],
    expired: [String] = []
  ) -> [String: Any] {
    let grantedPermissions = granted.map {
      [
        "permission": $0,
        "status": "granted"
      ]
    }
    let declinedPermissions = declined.map {
      [
        "permission": $0,
        "status": "declined"
      ]
    }
    let expiredPermissions = expired.map {
      [
        "permission": $0,
        "status": "expired"
      ]
    }
    return ["data": grantedPermissions + expiredPermissions + declinedPermissions]
  }
}

@objcMembers
class SampleRawRemotePermission: NSObject {
  static let missingTopLevelKey: [String: Any] = [:]
}
