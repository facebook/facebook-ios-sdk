/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

class CustomUpdateLocalizedText: NSObject, Codable {
  var defaultString: String
  var localizations: [String: String]

  init?(defaultString: String, localizations: [String: String]) {
    if defaultString.isEmpty {
      return nil
    }

    self.defaultString = defaultString
    self.localizations = localizations
  }

  enum CodingKeys: String, CodingKey {
    case defaultString = "default"
    case localizations
  }
}
