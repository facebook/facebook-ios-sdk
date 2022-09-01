/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKDialogConfigurationMapBuilder)
public final class _DialogConfigurationMapBuilder: NSObject, _DialogConfigurationMapBuilding {

  private enum Keys {
    static let name = "name"
    static let url = "url"
    static let versions = "versions"
  }

  public func buildDialogConfigurationMap(
    from rawConfigurations: [[String: Any]]
  ) -> [String: _DialogConfiguration] {

    var configurations = [String: _DialogConfiguration]()

    rawConfigurations.forEach { configuration in
      guard
        let name = configuration[Keys.name] as? String,
        !name.isEmpty,
        let rawURL = configuration[Keys.url] as? String,
        let url = URL(string: rawURL),
        let appVersions = configuration[Keys.versions] as? [Any],
        appVersions is [String] || appVersions is [Int],
        !appVersions.isEmpty
      else {
        return
      }

      configurations[name] = _DialogConfiguration(name: name, url: url, appVersions: appVersions)
    }

    return configurations
  }
}
