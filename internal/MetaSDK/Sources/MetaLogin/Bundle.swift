/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Bundle: AppConfigurationQuerying {
  private enum InfoDictionaryKey: String {
    case facebookAppID = "FacebookAppID"
    case metaAppID = "MetaAppID"
  }

  var facebookAppID: String? {
    string(for: .facebookAppID)
  }

  var metaAppID: String? {
    string(for: .metaAppID)
  }

  private func string(for key: InfoDictionaryKey) -> String? {
    object(forInfoDictionaryKey: key.rawValue) as? String
  }
}
