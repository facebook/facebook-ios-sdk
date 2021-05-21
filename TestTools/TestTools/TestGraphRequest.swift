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

@testable import FBSDKCoreKit

@objcMembers
public class TestGraphRequest: NSObject, GraphRequestProtocol {
  public var isGraphErrorRecoveryDisabled: Bool = false
  public var hasAttachments: Bool = false
  public var parameters: [String: Any] = [:]
  public var tokenString: String?
  public var graphPath: String = ""
  public var httpMethod = HTTPMethod.get
  public var version: String = ""
  public var flags: GraphRequestFlags = []
  public var stubbedConnection = TestGraphRequestConnection()
  public var capturedCompletionHandler: GraphRequestCompletion?
  public var startCallCount = 0
  public var cancelCallCount = 0

  public convenience init(
    graphPath: String,
    HTTPMethod: HTTPMethod
  ) {
    self.init()

    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any]
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    HTTPMethod: HTTPMethod
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.httpMethod = HTTPMethod
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    flags: GraphRequestFlags
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.flags = flags
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.tokenString = tokenString
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    HTTPMethod: HTTPMethod,
    flags: GraphRequestFlags
  ) {
    self.init()

    self.graphPath = graphPath
    self.parameters = parameters
    self.tokenString = tokenString
    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
    self.flags = flags
  }

  public convenience init(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    HTTPMethod: HTTPMethod,
    version: String
  ) {
    self.init()

    self.parameters = parameters
    self.tokenString = tokenString
    self.graphPath = graphPath
    self.httpMethod = HTTPMethod
    self.version = version
  }

  public func start(completion handler: GraphRequestCompletion? = nil) -> GraphRequestConnecting {
    capturedCompletionHandler = handler
    startCallCount += 1

    return stubbedConnection
  }

  public func cancel() {
    cancelCallCount += 1
  }

  public func formattedDescription() -> String {
    return "Test graph request"
  }
}
