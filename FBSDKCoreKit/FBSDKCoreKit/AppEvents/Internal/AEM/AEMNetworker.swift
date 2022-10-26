/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class AEMNetworker: NSObject, AEMNetworking {
  func startGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?,
    completion: @escaping FBGraphRequestCompletion
  ) {
    let graphRequest = GraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      httpMethod: method,
      flags: [.skipClientToken, .disableErrorRecovery]
    )

    graphRequest.start { _, result, error in
      completion(result, error)
    }
  }
}
