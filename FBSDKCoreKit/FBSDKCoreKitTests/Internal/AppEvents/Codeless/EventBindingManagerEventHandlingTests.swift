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

  var firstIndexPath: IndexPath {
    return IndexPath(row: 0, section: 0)
  }

  // MARK: - Touch Handling

  func testDispatchingTouchesToRnWithRnViewInHierarchy() {
    let touch = TestTouch()
    let (reactView, view) = ViewHierarchies.viewWithReactNativeAncestor(interactionEnabled: true)
    touch.stubbedView = view

    guard let expectedReactTag = (reactView as? TestReactNativeView)?.reactTag else {
      return XCTFail("Should have a tagged react native view")
    }
    let binding = TestEventBinding()
    manager.reactBindings = [expectedReactTag: binding]

    manager.handleReactNativeTouches(
      withHandler: nil,
      command: nil,
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
    let hierarchy = ViewHierarchies.viewWithReactNativeAncestor(interactionEnabled: false)
    touch.stubbedView = hierarchy.leaf

    let binding = TestEventBinding()
    manager.reactBindings = [5: binding]

    manager.handleReactNativeTouches(
      withHandler: nil,
      command: nil,
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
    let hierarchy = ViewHierarchies.viewWithReactNativeAncestor(interactionEnabled: false)
    touch.stubbedView = hierarchy.leaf

    let binding = TestEventBinding()
    manager.reactBindings = [3: binding]

    manager.handleReactNativeTouches(
      withHandler: nil,
      command: nil,
      touches: Set([touch]),
      eventName: "touchEnd"
    )
    XCTAssertFalse(
      binding.trackEventWasCalled,
      "Should not track a touch event for a non-bound bound react native view"
    )
  }

  func testSelectingTableViewCellMatchingIndexPath() {
    let (tableView, cell) = ViewHierarchies.nestedTableViewAndCell
    tableView.stub(cell: cell, forIndexPath: firstIndexPath)
    let binding = TestEventBinding(view: cell)

    manager.eventBindings = [binding]

    manager.handleDidSelectRow(
      with: [binding],
      target: nil,
      command: nil,
      tableView: tableView,
      indexPath: firstIndexPath
    )

    XCTAssertTrue(
      binding.trackEventWasCalled,
      "Should track an event when a cell can be retrieved using the given index path"
    )
  }

  func testSelectingMissingTableViewCell() {
    let (tableView, _) = ViewHierarchies.nestedTableViewAndCell
    let binding = TestEventBinding()

    manager.eventBindings = [binding]

    manager.handleDidSelectRow(
      with: [binding],
      target: nil,
      command: nil,
      tableView: tableView,
      indexPath: firstIndexPath
    )

    XCTAssertFalse(
      binding.trackEventWasCalled,
      "Should not track an event when a cell cannot be retrieved using the given index path"
    )
  }

  func testSelectingCollectionViewCellMatchingIndexPath() {
    let (collection, cell) = ViewHierarchies.nestedCollectionViewAndCell
    collection.stub(cell: cell, forIndexPath: firstIndexPath)
    let binding = TestEventBinding(view: cell)

    manager.eventBindings = [binding]

    manager.handleDidSelectItem(
      with: [binding],
      target: nil,
      command: nil,
      collectionView: collection,
      indexPath: firstIndexPath
    )

    XCTAssertTrue(
      binding.trackEventWasCalled,
      "Should track an event when an item can be retrieved using the given index path"
    )
  }

  func testSelectingMissingCollectionViewCell() {
    let (collection, _) = ViewHierarchies.nestedCollectionViewAndCell
    let binding = TestEventBinding()

    manager.eventBindings = [binding]

    manager.handleDidSelectItem(
      with: [binding],
      target: nil,
      command: nil,
      collectionView: collection,
      indexPath: firstIndexPath
    )

    XCTAssertFalse(
      binding.trackEventWasCalled,
      "Should not track an event when an item cannot be retrieved using the given index path"
    )
  }
}
