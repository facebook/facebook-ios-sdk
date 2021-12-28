/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

extension EventBindingManagerTests {

  var firstIndexPath: IndexPath {
    IndexPath(row: 0, section: 0)
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
