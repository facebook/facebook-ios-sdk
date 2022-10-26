/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

public typealias FBGraphRequestCompletion = (Any?, Error?) -> Void

@objc(FBAEMNetworking)
public protocol AEMNetworking {
  @objc(startGraphRequestWithGraphPath:parameters:tokenString:HTTPMethod:completion:)
  func startGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?,
    completion: @escaping FBGraphRequestCompletion
  )
}
