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
    let control = TestControl()
    let window = UIWindow()
    control.stubbedWindow = window
    manager.eventBindings = nil
    manager.match(control, delegate: self)

    XCTAssertNil(
      control.capturedAction,
      "Should not add an action to the control when there are no event bindings"
    )
  }

  func testMatchingViewWithoutWindow() {
    let control = TestControl()
    XCTAssertNotNil(manager.eventBindings, "There should be event bindings from setup")
    manager.match(control, delegate: self)

    XCTAssertNil(
      control.capturedAction,
      "Should not add an action to a control that is not in a window"
    )
  }

  func testMatchingControlWithWindow() {
    let control = TestControl()
    let window = UIWindow()
    control.stubbedWindow = window
    let binding = TestEventBinding(view: control)
    manager.eventBindings = [TestEventBinding(), binding]
    manager.match(control, delegate: self)

    XCTAssertNotNil(
      control.capturedAction,
      "Should add an action to a control that is in a window"
    )
  }

  func testMatchingReactNativeView() {
    let window = UIWindow()
    let view = TestReactNativeView()
    view.stubbedWindow = window

    let binding = TestEventBinding(view: view)
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    manager.eventBindings = [TestEventBinding(), binding]
    manager.match(view, delegate: self)

    XCTAssertEqual(
      self.manager.reactBindings?[view.reactTag] as? TestEventBinding,
      binding,
      "Should store the binding for the react tag that corresponds to the view"
    )
  }

  func testMatchingTableView() {
    let (tableView, cell) = ViewHierarchies.nestedTableViewAndCell
    let binding = TestEventBinding(view: cell)

    manager.eventBindings = [binding]
    manager.match(tableView, delegate: self)

    XCTAssertTrue(
      TestSwizzler.evidence.contains {
        $0.selector == #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))
      },
      "Should replace did select row at when matching a table view and a delegate"
    )
  }

  func testMatchingCollectionView() {
    let (collection, cell) = ViewHierarchies.nestedCollectionViewAndCell
    let binding = TestEventBinding(view: cell)

    manager.eventBindings = [binding]
    manager.match(collection, delegate: self)

    XCTAssertTrue(
      TestSwizzler.evidence.contains {
        $0.selector == #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:))
      },
      "Should replace did select item at when matching a collection view and a delegate"
    )
  }
}
