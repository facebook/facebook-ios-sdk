/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

final class EventBindingTests: XCTestCase {

  let window = UIWindow()
  let eventLogger = TestEventLogger()
  lazy var eventBindingManager = EventBindingManager(
    json: SampleRawRemoteEventBindings.sampleDictionary,
    swizzler: TestSwizzler.self,
    eventLogger: eventLogger
  )
  let buyButton = UIButton(type: .custom)
  let confirmButton = UIButton(type: .custom)
  let stepper = UIStepper()

  override func setUp() {
    super.setUp()

    let controller = UIViewController()
    let nav = UINavigationController(rootViewController: controller)

    let tab = UITabBarController()
    tab.viewControllers = [nav]
    window.rootViewController = tab

    let firstStackView = UIStackView()
    controller.view.addSubview(firstStackView)
    let secondStackView = UIStackView()
    firstStackView.addSubview(secondStackView)

    buyButton.setTitle("Buy", for: .normal)
    firstStackView.addSubview(buyButton)

    let firstStackPriceLabel = UILabel()
    firstStackPriceLabel.text = "$2.0"
    firstStackView.addSubview(firstStackPriceLabel)

    confirmButton.setTitle("Confirm", for: .normal)
    firstStackView.addSubview(confirmButton)

    let secondStackPriceLabel = UILabel()
    secondStackPriceLabel.text = "$3.0"
    secondStackView.addSubview(secondStackPriceLabel)

    secondStackView.addSubview(stepper)
  }

  func testDefaultNumberParser() {
    XCTAssertTrue(
      EventBinding.numberParser is AppEventsNumberParser,
      "The default number parser for an event binding should be an instance of FBSDKAppEventsNumberParser"
    )
  }

  func testCreatingWithDependencies() {
    let binding = EventBinding(json: [:], eventLogger: eventLogger)
    XCTAssertEqual(
      binding.eventLogger as? TestEventLogger,
      eventLogger,
      "Should store the provided event logger"
    )
  }

  func testEventBindingEquation() throws {
    // swiftlint:disable:next line_length
    let remoteEventBindings = try XCTUnwrap(SampleRawRemoteEventBindings.sampleDictionary["event_bindings"] as? [[String: Any]])
    let bindings = eventBindingManager.parseArray(remoteEventBindings)
    XCTAssertEqual(bindings[0], bindings[0])
    XCTAssertNotEqual(bindings[0], bindings[1])
  }

  func testParsing() {
    (0 ... 100).forEach { _ in
      let sampleData = SampleRawRemoteEventBindings.sampleDictionary
      eventBindingManager.parseArray(Fuzzer.randomize(json: sampleData) as? Array ?? [])
    }
  }

  func testTrackingSimpleEvent() {
    let binding = parsedBindings[0]

    binding.trackEvent(buyButton)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name("Quantity Changed"),
      "Tracking events should log the event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [AppEvents.ParameterName: String],
      [.init("_is_fb_codeless"): "1"],
      "Should track whether the event was codeless"
    )
  }

  func testTrackingComplexEvent() {
    let binding = parsedBindings[1]

    binding.trackEvent(buyButton)

    XCTAssertEqual(
      eventLogger.capturedEventName,
      AppEvents.Name("Add To Cart"),
      "Tracking events should log the event name"
    )
    XCTAssertEqual(
      eventLogger.capturedParameters as? [AppEvents.ParameterName: String],
      [.init("_is_fb_codeless"): "1"],
      "Should track whether the event was codeless"
    )
  }

  var parsedBindings: [EventBinding] {
    // swiftlint:disable:next force_cast
    let remoteEventBindings = SampleRawRemoteEventBindings.sampleDictionary["event_bindings"] as! [[String: Any]]
    return eventBindingManager.parseArray(remoteEventBindings)
  }
}
