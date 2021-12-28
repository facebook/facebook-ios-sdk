/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class ViewHierarchyTests: XCTestCase {
  let scrollview = UIScrollView()
  let label = UILabel()
  let textField = UITextField()
  let textView = UITextView()
  let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 5, height: 20))

  override func setUp() {
    super.setUp()

    label.text = NSLocalizedString("I am a label", comment: "")
    scrollview.addSubview(label)

    textField.text = NSLocalizedString("I am a text field", comment: "")
    textField.placeholder = NSLocalizedString("text field placeholder", comment: "")
    scrollview.addSubview(textField)

    textView.text = NSLocalizedString("I am a text view", comment: "")
    scrollview.addSubview(textView)

    btn.setTitle(NSLocalizedString("I am a button", comment: ""), for: .normal)
    scrollview.addSubview(btn)
  }

  func testRecursiveCaptureTree() throws {
    let optionalTree = ViewHierarchy.recursiveCaptureTree(
      withCurrentNode: scrollview,
      targetNode: nil,
      objAddressSet: nil,
      hash: false
    )

    let tree = try XCTUnwrap(optionalTree)

    XCTAssertEqual(tree["classname"] as? String, "UIScrollView")

    let childviews = try XCTUnwrap(tree["childviews"] as? [[String: Any]])
    XCTAssertEqual(childviews.count, 4)
    XCTAssertEqual(childviews[0]["classname"] as? String, "UILabel")
    XCTAssertEqual(childviews[1]["classname"] as? String, "UITextField")
    XCTAssertEqual(childviews[2]["classname"] as? String, "UITextView")
    XCTAssertEqual(childviews[3]["classname"] as? String, "UIButton")
  }

  func testGetText() {
    XCTAssertEqual(ViewHierarchy.getText(label), "I am a label")
    XCTAssertEqual(ViewHierarchy.getText(textField), "I am a text field")
    XCTAssertEqual(ViewHierarchy.getText(textView), "I am a text view")
    XCTAssertEqual(ViewHierarchy.getText(btn), "I am a button")

    // test for no text
    XCTAssertEqual(ViewHierarchy.getText(scrollview), "")
  }

  func testGetHint() {
    XCTAssertEqual(ViewHierarchy.getHint(textField), "text field placeholder")

    // test for getting hint for UITextField with inside labels ("text field placeholder" + " I am a label")
    textField.addSubview(label)
    XCTAssertEqual(ViewHierarchy.getHint(textField), "text field placeholder I am a label")

    // test for no hint
    XCTAssertEqual(ViewHierarchy.getHint(label), "")

    // test for getting hint for UINavigationController
    let navigationController = UINavigationController()
    XCTAssertEqual(ViewHierarchy.getHint(navigationController), "")
    let viewController = UIViewController()
    navigationController.addChild(viewController)
    XCTAssertEqual(ViewHierarchy.getHint(navigationController), "UIViewController")
  }

  func testGetInstanceVariable() {
    // empty args should cause no-op.
    XCTAssertEqual(getVariableFromInstance(nil, "anything prop") as? NSNull, NSNull())
    XCTAssertEqual(getVariableFromInstance(NSObject(), nil) as? NSNull, NSNull())

    // If there is no ivar, should return nil.
    XCTAssertEqual(getVariableFromInstance(NSObject(), "some_made_up_property_123456") as? NSNull, NSNull())

    // this only works on Objective-C objects
    XCTAssertEqual(getVariableFromInstance(ObjCTestObject(), "_a") as? String, "BLAH")
  }
}
