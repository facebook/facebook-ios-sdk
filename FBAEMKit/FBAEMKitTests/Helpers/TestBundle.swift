/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class TestBundle: Bundle {
  var infoDictionaryKey: String?
  var stubbedInfoDictionaryObject: Any?

  override func object(forInfoDictionaryKey key: String) -> Any? {
    infoDictionaryKey = key
    return stubbedInfoDictionaryObject
  }
}
