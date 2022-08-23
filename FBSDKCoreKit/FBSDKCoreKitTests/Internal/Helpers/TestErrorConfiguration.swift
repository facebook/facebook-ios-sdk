/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
final class TestErrorConfiguration: NSObject, _ErrorConfigurationProtocol {
  var capturedRecoveryConfigurationCode: String?
  var capturedRecoveryConfigurationSubcode: String?
  var capturedGraphRequest: GraphRequestProtocol?
  var stubbedRecoveryConfiguration: _ErrorRecoveryConfiguration?

  func recoveryConfiguration(
    forCode code: String?,
    subcode: String?,
    request: GraphRequestProtocol
  ) -> _ErrorRecoveryConfiguration? {
    capturedRecoveryConfigurationCode = code
    capturedRecoveryConfigurationSubcode = subcode
    capturedGraphRequest = request

    guard let recoveryConfiguration = stubbedRecoveryConfiguration else {
      fatalError("Must have a recovery configuration stubbed")
    }
    return recoveryConfiguration
  }
}
