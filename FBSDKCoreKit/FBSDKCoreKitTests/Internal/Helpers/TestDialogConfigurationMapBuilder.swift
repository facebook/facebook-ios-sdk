/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestDialogConfigurationMapBuilder: _DialogConfigurationMapBuilding {

  var capturedRawConfigurations: [[String: Any]]?

  func buildDialogConfigurationMap(
    from rawConfigurations: [[String: Any]]
  ) -> [String: _DialogConfiguration] {
    capturedRawConfigurations = rawConfigurations
    return [:]
  }
}
