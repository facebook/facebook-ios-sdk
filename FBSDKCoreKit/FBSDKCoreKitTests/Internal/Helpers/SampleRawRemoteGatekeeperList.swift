/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

enum SampleRawRemoteGatekeeperList {
  static let valid: [String: Any] = {
    [
      "data": [
        [
          "gatekeepers": [
            SampleRawRemoteGatekeeper.validEnabled,
            SampleRawRemoteGatekeeper.validDisabled
          ]
        ]
      ]
    ]
  }()
  static let validHeterogeneous: [String: Any] = {
    [
      "data": [
        [
          "gatekeepers": [
            SampleRawRemoteGatekeeper.valid(name: "foo", enabled: true),
            SampleRawRemoteGatekeeper.valid(name: "bar", enabled: false)
          ]
        ]
      ]
    ]
  }()
  static let missingGatekeepers: [String: Any] = {
    [
      "data": []
    ]
  }()
  static let emptyGatekeepers: [String: Any] = {
    [
      "data": [
        [
          "gatekeepers": []
        ]
      ]
    ]
  }()
}
