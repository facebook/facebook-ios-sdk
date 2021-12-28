/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum SampleRawDialogConfigurations {

  enum Keys {
    static let name = "name"
    static let url = "url"
    static let versions = "versions"
  }

  static let empty = [String: Any]()

  static func createValid(name: String) -> [String: Any] {
    [
      Keys.name: name,
      Keys.url: "https://www.example.com",
      Keys.versions: ["1"]
    ]
  }
}
