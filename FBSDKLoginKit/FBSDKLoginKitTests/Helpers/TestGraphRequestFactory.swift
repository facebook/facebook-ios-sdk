// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools

@objcMembers
class TestGraphRequestFactory: NSObject, GraphRequestProviding {

  var capturedGraphPath: String?
  var capturedParameters = [AnyHashable: Any]()
  var capturedTokenString: String?
  var capturedHttpMethod: HTTPMethod?
  var capturedFlags: GraphRequestFlags = []
  var capturedRequests = [TestGraphRequest]()

  // MARK: - GraphRequestProviding

  func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [AnyHashable: Any],
    tokenString: String?,
    httpMethod method: HTTPMethod?,
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedHttpMethod = method
    capturedFlags = flags

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters as? [String: Any] ?? [:],
      tokenString: tokenString,
      HTTPMethod: method ?? .get,
      flags: flags
    )
    capturedRequests.append(request)
    return request
  }

  func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    httpMethod method: HTTPMethod
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedHttpMethod = method

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      HTTPMethod: method
    )
    capturedRequests.append(request)
    return request
  }

  func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    version: String?,
    httpMethod method: HTTPMethod
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedTokenString = tokenString
    capturedHttpMethod = method

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      tokenString: tokenString,
      HTTPMethod: method,
      flags: []
    )
    capturedRequests.append(request)
    return request
  }

  func createGraphRequest(
    withGraphPath graphPath: String
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath

    let request = TestGraphRequest(graphPath: graphPath, HTTPMethod: .get)
    capturedRequests.append(request)
    return request
  }

  func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any]
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      HTTPMethod: .get
    )
    capturedRequests.append(request)
    return request
  }

  func createGraphRequest(
    withGraphPath graphPath: String,
    parameters: [AnyHashable: Any],
    flags: GraphRequestFlags
  ) -> GraphRequestProtocol {
    capturedGraphPath = graphPath
    capturedParameters = parameters
    capturedFlags = flags

    let request = TestGraphRequest(
      graphPath: graphPath,
      parameters: parameters as? [String: Any] ?? [:],
      tokenString: nil,
      HTTPMethod: .get,
      flags: flags
    )
    capturedRequests.append(request)
    return request
  }
}
