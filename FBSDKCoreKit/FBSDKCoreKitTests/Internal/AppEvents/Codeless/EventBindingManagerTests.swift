/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

@objc
protocol WindowMoving {
  func didMoveToWindow()
}

final class EventBindingManagerTests: XCTestCase, UITableViewDelegate, UICollectionViewDelegate {

  lazy var manager = EventBindingManager(
    json: SampleRawRemoteEventBindings.sampleDictionary,
    swizzler: TestSwizzler.self,
    eventLogger: eventLogger
  )

  var bindings = SampleEventBinding.validEventBindings
  let eventLogger = TestEventLogger()

  let expectedEvidenceWithoutReactNative = [
    SwizzleEvidence(selector: #selector(UIControl.didMoveToWindow), class: UIControl.self),
    SwizzleEvidence(selector: #selector(setter: UITableView.delegate), class: UITableView.self),
    SwizzleEvidence(selector: #selector(setter: UICollectionView.delegate), class: UICollectionView.self),
  ]

  override func setUp() {
    super.setUp()

    registerReactNativeClasses()
    TestSwizzler.reset()
  }

  // MARK: - Dependencies

  func testCreatingCustom() {
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    XCTAssertTrue(
      manager.swizzler is TestSwizzler.Type,
      "Should be created with the provided swizzling type"
    )
    XCTAssertEqual(
      manager.eventLogger as? TestEventLogger,
      eventLogger,
      "Should be created with the provided event logger"
    )
  }

  func testCreatingCustomWithJson() {
    manager = EventBindingManager(
      json: ["some": "stuff"],
      swizzler: TestSwizzler.self,
      eventLogger: eventLogger
    )
    XCTAssertTrue(
      manager.swizzler is TestSwizzler.Type,
      "Should be created with the provided swizzling type"
    )
  }

  func testCreatingWithReactNativeUnavailable() {
    deregisterReactNativeClasses()
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    XCTAssertFalse(
      manager.hasReactNative,
      "Should detect if react native is in the runtime"
    )
    manager.validClasses.forEach { item in
      switch item.base {
      case is UIControl.Type: break
      case is UICollectionView.Type: break
      case is UITableView.Type: break
      default: XCTFail("\(item.description) should not be considered valid")
      }
    }
  }

  func testCreatingWithReactNativeAvailable() {
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    XCTAssertTrue(
      manager.hasReactNative,
      "Should detect if react native is in the runtime"
    )
    let classNames = Set(manager.validClasses.map { $0.description })
    let expected = Set([
      "RCTTextView",
      "RCTImageView",
      "UITableView",
      "UIControl",
      "UICollectionView",
      "RCTView",
    ])
    XCTAssertEqual(
      classNames,
      expected,
      "Should have a known set of valid classes"
    )
  }

  // MARK: - Starting

  func testStartingWithEventsWhenStarted() {
    manager.isStarted = true
    manager.start()

    XCTAssertTrue(TestSwizzler.evidence.isEmpty)
  }

  func testStartingWithEventsWhenNotStarted() {
    deregisterReactNativeClasses()
    manager = EventBindingManager(
      json: SampleRawRemoteEventBindings.sampleDictionary,
      swizzler: TestSwizzler.self,
      eventLogger: eventLogger
    )
    manager.isStarted = false
    manager.start()

    XCTAssertEqual(
      TestSwizzler.evidence,
      expectedEvidenceWithoutReactNative
    )
  }

  func testStartingWithoutEventsWhenStarted() {
    manager.eventBindings = []
    manager.isStarted = true
    manager.start()

    XCTAssertTrue(TestSwizzler.evidence.isEmpty)
  }

  func testStartingWithoutEventsWhenNotStarted() {
    manager.eventBindings = []
    manager.isStarted = false
    manager.start()

    XCTAssertTrue(TestSwizzler.evidence.isEmpty)
  }

  func testStartingWithReactNativeClasses() {
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)

    // Updating bindings will actually call start if it is not in a started state
    manager.isStarted = true
    manager.updateBindings(bindings)

    manager.isStarted = false
    manager.start()

    // This is ugly but there is no good way to do this in Swift.
    let expected = "["
      .appending(
        [
          "FBSDKCoreKitTests.SwizzleEvidence(selector: didMoveToWindow, class: UIControl)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: didMoveToWindow, class: RCTView)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: didMoveToWindow, class: RCTTextView)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: didMoveToWindow, class: RCTImageView)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: _updateAndDispatchTouches:eventName:, class: RCTTouchHandler)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: setDelegate:, class: UITableView)",
          "FBSDKCoreKitTests.SwizzleEvidence(selector: setDelegate:, class: UICollectionView)",
        ]
          .joined(separator: ", ")
      )
      .appending("]")

    XCTAssertEqual(
      TestSwizzler.evidence.description,
      expected
    )
  }

  // MARK: - Updating Bindings

  func testUpdatingEventBindings() {
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    manager.reactBindings = ["foo": SampleEventBinding.createValid(withName: "foo")]
    manager.updateBindings(bindings)

    XCTAssertEqual(
      manager.eventBindings,
      bindings,
      "Should persist updated event bindings"
    )
    XCTAssertEqual(
      manager.reactBindings?.count,
      0,
      "Should clear react bindings when updating bindings"
    )
  }

  func testUpdatingEventBindingsWithIdenticalBindings() {
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    manager.updateBindings(bindings)
    manager.updateBindings(bindings)

    XCTAssertEqual(
      manager.eventBindings,
      bindings,
      "Should not add duplicate event bindings"
    )
  }

  func testUpdatingEventBindingsWithRecreatedBindings() {
    manager.updateBindings(bindings)

    guard let eventBindings = manager.eventBindings else {
      return XCTFail("There should be event bindings on the manager")
    }

    eventBindings.enumerated().forEach { pair in
      let (index, element) = pair
      XCTAssertTrue(
        element.isEqual(to: bindings[index]),
        "Bindings with the same information should be considered equal"
      )
    }
  }

  func testUpdatingEventBindingsWithDifferentBindingsDifferentNumberOfBindings() {
    bindings.append(SampleEventBinding.createValid(withName: "foo"))
    manager.updateBindings(bindings)

    XCTAssertEqual(
      manager.eventBindings,
      bindings,
      "Setting a different number of bindings from the number of stored bindings should overwrite the stored bindings"
    )
  }

  func testUpdatingEventBindingsWithDifferentBindingsSameNumberOfBindings() {
    let binding = SampleEventBinding.createValid(withName: "foo")
    let binding2 = SampleEventBinding.createValid(withName: "bar")
    let binding3 = SampleEventBinding.createValid(withName: "baz")

    manager.updateBindings([binding, binding2])
    manager.updateBindings([binding2, binding3])

    XCTAssertEqual(
      manager.eventBindings,
      [binding2, binding3],
      "Setting different bindings from the stored bindings should overwrite the stored bindings"
    )
  }

  func testUpdatingBindingsStarts() {
    manager.isStarted = false
    manager = EventBindingManager(swizzler: TestSwizzler.self, eventLogger: eventLogger)
    manager.updateBindings(bindings)

    XCTAssertTrue(
      manager.isStarted,
      "Updating bindings should start the manager if it is not started"
    )
  }

  // MARK: - Helpers

  func registerReactNativeClasses() {
    if objc_lookUpClass("RCTRootView") == nil,
       let touchHandler: AnyClass = objc_allocateClassPair(NSObject.self, "RCTTouchHandler", 0),
       let reactRootView: AnyClass = objc_allocateClassPair(NSObject.self, "RCTRootView", 0),
       let imageView: AnyClass = objc_allocateClassPair(NSObject.self, "RCTImageView", 0),
       let textView: AnyClass = objc_allocateClassPair(NSObject.self, "RCTTextView", 0),
       let view: AnyClass = objc_allocateClassPair(NSObject.self, "RCTView", 0) {
      objc_registerClassPair(touchHandler)
      objc_registerClassPair(reactRootView)
      objc_registerClassPair(imageView)
      objc_registerClassPair(textView)
      objc_registerClassPair(view)
    }
  }

  func deregisterReactNativeClasses() {
    if let touchHandler = objc_lookUpClass("RCTTouchHandler"),
       let rootViewClass = objc_lookUpClass("RCTRootView"),
       let imageView = objc_lookUpClass("RCTImageView"),
       let textView = objc_lookUpClass("RCTTextView"),
       let view = objc_lookUpClass("RCTView") {
      objc_disposeClassPair(touchHandler)
      objc_disposeClassPair(rootViewClass)
      objc_disposeClassPair(imageView)
      objc_disposeClassPair(textView)
      objc_disposeClassPair(view)
    }
  }

  enum ViewHierarchies {

    static func viewWithReactNativeAncestor(interactionEnabled: Bool) -> (root: UIView, leaf: UIView) {
      let reactView1 = TestReactNativeView()
      reactView1.isUserInteractionEnabled = false
      let reactView2 = TestReactNativeView()
      reactView2.isUserInteractionEnabled = interactionEnabled
      let view = UIView()
      reactView2.addSubview(reactView1)
      reactView1.addSubview(view)

      return (root: reactView2, leaf: view)
    }

    static var nestedTableViewAndCell: (tableView: TestTableView, cell: UITableViewCell) {
      let window = UIWindow()
      let tableView = TestTableView()
      tableView.stubbedWindow = window
      let view = TestView()
      view.stubbedWindow = window
      let cell = UITableViewCell()
      view.addSubview(tableView)
      tableView.addSubview(cell)

      return (tableView, cell)
    }

    static var nestedCollectionViewAndCell: (tableView: TestCollectionView, cell: UICollectionViewCell) {
      let window = UIWindow()
      let collectionView = TestCollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
      )
      collectionView.stubbedWindow = window
      let view = TestView()
      view.stubbedWindow = window
      let cell = UICollectionViewCell()
      view.addSubview(collectionView)
      collectionView.addSubview(cell)

      return (collectionView, cell)
    }
  }
}
