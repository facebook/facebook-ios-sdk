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
public final class TestGraphRequestConnection: NSObject, GraphRequestConnecting {

  public typealias Completion = @convention(block) (GraphRequestConnecting, Any?, Error?) -> Void

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
