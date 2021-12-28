/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools

class TestBridgeAPIProtocol: NSObject, BridgeAPIProtocol {
  var stubbedRequestURL = SampleURLs.valid
  var stubbedRequestURLError: Error?
  var stubbedResponseParameters = [String: Any]()
  var capturedRequestUrlActionID: String?
  var capturedRequestUrlScheme: String?
  var capturedRequestUrlMethodName: String?
  var capturedRequestUrlParameters: [String: Any]?
  var capturedResponseActionID: String?
  var capturedResponseQueryParameters: [String: Any]?
  var capturedResponseCancelledRef: UnsafeMutablePointer<ObjCBool>?

  func requestURL(
    withActionID actionID: String,
    scheme: String,
    methodName: String,
    parameters: [String: Any]
  ) throws -> URL {
    capturedRequestUrlActionID = actionID
    capturedRequestUrlScheme = scheme
    capturedRequestUrlMethodName = methodName
    capturedRequestUrlParameters = parameters

    if let error = stubbedRequestURLError {
      throw error
    }

    return stubbedRequestURL
  }

  func responseParameters(
    forActionID actionID: String,
    queryParameters: [String: Any],
    cancelled cancelledRef: UnsafeMutablePointer<ObjCBool>?
  ) throws -> [String: Any] {
    capturedResponseActionID = actionID
    capturedResponseQueryParameters = queryParameters
    capturedResponseCancelledRef = cancelledRef

    return stubbedResponseParameters
  }
}
