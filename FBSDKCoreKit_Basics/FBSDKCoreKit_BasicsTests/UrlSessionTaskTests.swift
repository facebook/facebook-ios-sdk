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
import TestTools
import XCTest

class UrlSessionTaskTests: XCTestCase {

  let dataTask = TestSessionDataTask()
  let provider = TestSessionProvider()
  lazy var task = UrlSessionTask(
    request: SampleURLRequest.valid,
    fromSession: provider,
    completionHandler: nil
  )! // swiftlint:disable:this force_unwrapping

  override func setUp() {
    super.setUp()

    provider.stubbedDataTask = dataTask
  }

  func testStarting() {
    task.start()

    XCTAssertEqual(
      dataTask.resumeCallCount,
      1,
      "Starting a session task should resume the underlying data task"
    )
  }

  func testStopping() {
    task.cancel()

    XCTAssertEqual(
      dataTask.cancelCallCount,
      1,
      "Cancelling a session task should cancel the underlying data task"
    )
  }

  func testState() {
    dataTask.stubbedState = .running
    XCTAssertEqual(
      task.state,
      .running,
      "Should return the state of the underlying data task"
    )
  }
}
