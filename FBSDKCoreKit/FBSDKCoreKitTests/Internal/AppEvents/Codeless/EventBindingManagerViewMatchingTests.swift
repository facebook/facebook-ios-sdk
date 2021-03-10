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

import XCTest

extension EventBindingManagerTests {

  // MARK: - View Matching

  func testMatchingViewWithoutEventBindings() {
    let control = ViewHierarchies.validControl(isNestedInWindow: true).leaf
    manager.eventBindings = nil
    manager.match(control, delegate: self)

    XCTAssertNil(
      control.capturedAction,
      "Should not add an action to the control when there are no event bindings"
    )
  }

  func testMatchingViewWithoutWindow() {
    let control = ViewHierarchies.validControl(isNestedInWindow: false).leaf
    XCTAssertNotNil(manager.eventBindings, "There should be event bindings from setup")
    manager.match(control, delegate: self)

    XCTAssertNil(
      control.capturedAction,
      "Should not add an action to a control that is not in a window"
    )
  }

  func testMatchingControlWithWindow() {
    let expectation = XCTestExpectation(description: name)
    let control = ViewHierarchies.validControl(isNestedInWindow: true).leaf
    let binding = TestEventBinding(view: control)
    manager.eventBindings = [TestEventBinding(), binding]
    manager.match(control, delegate: self)

    DispatchQueue.main.asyncAfter(deadline: .now()) {
      XCTAssertNotNil(
        control.capturedAction,
        "Should add an action to a control that is in a window"
      )
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
  }

  func testMatchingReactNativeView() {
    let expectation = XCTestExpectation(description: name)
    let view = ViewHierarchies.validReactNative
    let binding = TestEventBinding(view: view)
    manager = EventBindingManager(swizzler: TestSwizzler.self)
    manager.eventBindings = [TestEventBinding(), binding]
    manager.match(view, delegate: self)

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      XCTAssertEqual(
        self.manager.reactBindings?[view.reactTag] as? TestEventBinding,
        binding,
        "Should store the binding for the react tag that corresponds to the view"
      )
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
  }
}
