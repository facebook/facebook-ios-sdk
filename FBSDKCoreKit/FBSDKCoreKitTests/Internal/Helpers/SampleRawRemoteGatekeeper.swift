/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum SampleRawRemoteGatekeeper {

  static func valid(name: String, enabled: Bool) -> [String: Any] {
    [
      "key": name,
      "value": enabled,
    ]
  }

  static let validEnabled = [
    "key": "foo",
    "value": true,
  ] as [String: Any]

  static let validDisabled = [
    "key": "foo",
    "value": false,
  ] as [String: Any]

  static let missingKey = [
    "value": false,
  ]

  static let missingValue = [
    "key": "foo",
  ]
}
