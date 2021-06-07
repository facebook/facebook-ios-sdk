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

@objcMembers
public class TestGraphRequestConnection: NSObject, GraphRequestConnecting {

  public typealias Completion = @convention(block) (GraphRequestConnecting, AnyObject?, Error?) -> Void

  public struct Request {
    public let request: GraphRequestProtocol
    public let completion: GraphRequestCompletion
  }

  public var timeout: TimeInterval = 0
  public var delegate: GraphRequestConnectionDelegate? // swiftlint:disable:this weak_delegate
  public var capturedRequest: GraphRequestProtocol?
  public var capturedRequests = [GraphRequestProtocol]()
  public var capturedCompletion: GraphRequestCompletion?
  public var capturedCompletions = [Completion]()
  public var startCallCount = 0
  public var cancelCallCount = 0

  // Enables us to use the internal requests property
  public var graphRequests = [Request]()

  public func add(_ request: GraphRequestProtocol, completion handler: @escaping GraphRequestCompletion) {
    graphRequests.append(
      Request(
        request: request,
        completion: handler
      )
    )
    capturedRequest = request
    capturedRequests.append(request)
    capturedCompletion = handler
    capturedCompletions.append(handler)
  }

  public func start() {
    startCallCount += 1
  }

  public func cancel() {
    cancelCallCount += 1
  }
}
