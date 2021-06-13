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
