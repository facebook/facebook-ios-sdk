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

import TestTools
import XCTest

class FBSDKEventBindingTests: XCTestCase {

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
    let remoteEventBindings = try XCTUnwrap(SampleRawRemoteEventBindings.sampleDictionary["event_bindings"] as? [Any])
    let bindings = eventBindingManager.parseArray(remoteEventBindings)
    XCTAssertEqual(bindings[0], bindings[0])
    XCTAssertNotEqual(bindings[0], bindings[1])
  }

  func testParsing() {
    (0...100).forEach { _ in
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
      eventLogger.capturedParameters as? [String: String],
      ["_is_fb_codeless": "1"],
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
      eventLogger.capturedParameters as? [String: String],
      ["_is_fb_codeless": "1"],
      "Should track whether the event was codeless"
    )
  }

  var parsedBindings: [EventBinding] {
    // swiftlint:disable:next force_cast
    let remoteEventBindings = SampleRawRemoteEventBindings.sampleDictionary["event_bindings"] as! [Any]
    return eventBindingManager.parseArray(remoteEventBindings)
  }
}
