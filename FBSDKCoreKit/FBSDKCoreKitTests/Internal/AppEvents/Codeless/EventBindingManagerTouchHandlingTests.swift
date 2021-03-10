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

  // MARK: - React Native Touch Handling

  func testDispatchingTouchesToRnWithRnViewInHierarchy() {
    let touch = TestTouch()
    let hierarchy = ViewHierarchies.validReactNativeAncestor(interactionEnabled: true)
    touch.stubbedView = hierarchy.leaf

    let binding = TestEventBinding()
    manager.reactBindings = [5: binding]

    manager.handleReactNativeTouches(
      withHandler: "unused",
      command: #selector(copy), // Placeholder selector (required but unused in production code)
      touches: Set([touch]),
      eventName: "touchEnd"
    )
    XCTAssertTrue(
      binding.trackEventWasCalled,
      "Should track a touch event for a bound react native view that is user interaction enabled"
    )
  }

  func testDispatchingTouchesToRnWithUserInteractionDisabled() {
    let touch = TestTouch()
    let hierarchy = ViewHierarchies.validReactNativeAncestor(interactionEnabled: false)
    touch.stubbedView = hierarchy.leaf

    let binding = TestEventBinding()
    manager.reactBindings = [5: binding]

    manager.handleReactNativeTouches(
      withHandler: "unused",
      command: #selector(copy), // Placeholder selector (required but unused in production code)
      touches: Set([touch]),
      eventName: "touchEnd"
    )
    XCTAssertTrue(
      binding.trackEventWasCalled,
      "Will track a touch event for a bound react native view that is not user interaction enabled"
    )
  }

  func testDispatchingTouchesToRnWithoutRnViewInHierarchy() {
    let touch = TestTouch()
    let hierarchy = ViewHierarchies.validReactNativeAncestor(interactionEnabled: false)
    touch.stubbedView = hierarchy.leaf

    let binding = TestEventBinding()
    manager.reactBindings = [3: binding]

    manager.handleReactNativeTouches(
      withHandler: "unused",
      command: #selector(copy), // Placeholder selector (required but unused in production code)
      touches: Set([touch]),
      eventName: "touchEnd"
    )
    XCTAssertFalse(
      binding.trackEventWasCalled,
      "Should not track a touch event for a non-bound bound react native view"
    )
  }
}
