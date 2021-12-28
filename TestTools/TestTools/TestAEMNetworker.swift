/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit

public class TestAEMNetworker: NSObject, AEMNetworking {

  public var capturedGraphPath: String?
  public var capturedParameters = [String: Any]()
  public var capturedTokenString: String?
  public var capturedHttpMethod: String?
  public var capturedCompletionHandler: FBGraphRequestCompletion?
  public var startCallCount = 0

  public func startGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?,
    completion: @escaping FBGraphRequestCompletion
  ) {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedHttpMethod = method
    capturedCompletionHandler = completion
    startCallCount += 1
  }
}
