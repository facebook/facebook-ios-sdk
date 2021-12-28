/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

@objcMembers
public class TestSessionDataTask: NSObject, SessionDataTask {
  public var resumeCallCount = 0
  public var cancelCallCount = 0
  public var stubbedState: URLSessionTask.State = .completed

  public var state: URLSessionTask.State {
    stubbedState
  }

  public func resume() {
    resumeCallCount += 1
  }

  public func cancel() {
    cancelCallCount += 1
  }
}

@objcMembers
public class TestSessionProvider: NSObject, SessionProviding {
  /// A data task to return from `dataTask(with:completion:)`
  public var stubbedDataTask: SessionDataTask?
  /// The completion handler to be invoked in the test
  public var capturedCompletion: ((Data?, URLResponse?, Error?) -> Void)?
  /// The url request for the data task
  public var capturedRequest: URLRequest?
  public var dataTaskCallCount = 0

  public func dataTask(
    with request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
  ) -> SessionDataTask {
    dataTaskCallCount += 1
    capturedRequest = request
    capturedCompletion = completionHandler
    return stubbedDataTask ?? TestSessionDataTask()
  }
}
