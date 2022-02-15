/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import TestTools
import XCTest

final class FeatureExtractorTests: XCTestCase {
  var rules: [String: Any] = [:]
  let viewHierarchy: [String: Any] = [
    "screenname": "UITabBarController",
    "view": [
      [
        "classname": "UIWindow",
        "classtypebitmask": "0",
        "childviews": [
          [
            "classname": "UITabBarController",
            "classtypebitmask": "131072",
            "childviews": [
              [
                "classname": "UINavigationController",
                "classtypebitmask": "131072",
                "childviews": [
                  [
                    "classname": "CheckoutViewController",
                    "classtypebitmask": "131072",
                    "childviews": [
                      [
                        "classname": "UIStackView",
                        "classtypebitmask": "0",
                        "childviews": [
                          [
                            "classname": "UILabel",
                            "classtypebitmask": "1024",
                            "text": "Order Summary",
                          ],
                          [
                            "classname": "UIStackView",
                            "classtypebitmask": "0",
                            "childviews": [
                              [
                                "classname": "UIView",
                                "classtypebitmask": "0",
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1024",
                                "text": "Coffee 5",
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "Price: $5.99",
                              ],
                            ],
                          ],
                          [
                            "classname": "UIStackView",
                            "classtypebitmask": "0",
                            "childviews": [
                              [
                                "classname": "UIView",
                                "classtypebitmask": "0",
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1024",
                                "text": "Quantity",
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1",
                              ],
                            ],
                          ],
                          [
                            "classname": "UITextField",
                            "classtypebitmask": "2056",
                            "hint": "Credit Card Credit Card",
                          ],
                          [
                            "classname": "UITextField",
                            "classtypebitmask": "2056",
                            "hint": "Shipping Address Shipping Address",
                          ],
                          [
                            "classname": "UIButton",
                            "classtypebitmask": "24",
                            "is_interacted": 1,
                            "hint": "Confirm Order",
                          ],
                        ],
                      ],
                    ],
                  ],
                ],
              ],
              [
                "classname": "UITabBar",
                "classtypebitmask": "0",
              ],
            ],
          ],
        ],
      ],
    ],
  ]

  let interactedNode: [String: Any] = [
    "classname": "UIButton",
    "classtypebitmask": "24",
    "is_interacted": 1,
    "hint": "Confirm Order",
  ]

  let siblings = [
    [
      "classname": "UILabel",
      "classtypebitmask": "1024",
      "text": "Order Summary",
    ],
    [
      "classname": "UIStackView",
      "classtypebitmask": "0",
      "childviews": [
        [
          "classname": "UIView",
          "classtypebitmask": "0",
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1024",
          "text": "Coffee 5",
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "Price: $5.99",
        ],
      ],
    ],
    [
      "classname": "UIStackView",
      "classtypebitmask": "0",
      "childviews": [
        [
          "classname": "UIView",
          "classtypebitmask": "0",
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1024",
          "text": "Quantity",
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1",
        ],
      ],
    ],
    [
      "classname": "UITextField",
      "classtypebitmask": "2056",
      "hint": "Credit Card Credit Card",
    ],
    [
      "classname": "UITextField",
      "classtypebitmask": "2056",
      "hint": "Shipping Address Shipping Address",
    ],
    [
      "classname": "UIButton",
      "classtypebitmask": "24",
      "is_interacted": 1,
      "hint": "Confirm Order",
    ],
  ]

  let modelManager = TestOnDeviceMLModelManager()

  override func setUpWithError() throws { // swiftlint:disable:this overridden_super_call
    super.setUp()

    let bundle = Bundle(for: Self.self)
    let fileURL = bundle.path(
      forResource: "FBSDKTextClassifyRules",
      ofType: "json"
    ) ?? ""
    if !fileURL.isEmpty {
      let data = try XCTUnwrap(NSData(contentsOfFile: fileURL, options: .mappedIfSafe))
      rules = try TypeUtility.jsonObject(
        with: data as Data
      ) as! [String: Any] // swiftlint:disable:this force_cast
    }
    FeatureExtractor.configureWithRules(modelManager)
    modelManager.rulesForKey = rules

    FeatureExtractor.loadRules(forKey: "MTML")
  }

  override func tearDown() {
    super.tearDown()

    FeatureExtractor.reset()
  }

  func testGetDenseFeature() {
    let denseFeature = FeatureExtractor.getDenseFeatures(
      viewHierarchy
    )! // swiftlint:disable:this force_unwrapping

    var denseFeatureArray: [Int] = []
    for feature in 0 ..< 30 {
      denseFeatureArray.append(Int(denseFeature[feature]))
    }
    XCTAssertEqual(
      denseFeatureArray,
      [0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
  }

  func testGetDenseFeatureParsing() {
    for _ in 0 ..< 100 {
      FeatureExtractor.getDenseFeatures(
        Fuzzer.randomize(json: viewHierarchy) as! [String: Any] // swiftlint:disable:this force_cast
      )
    }
  }

  func testGetTextFeature() {
    XCTAssertEqual(
      FeatureExtractor.getTextFeature(
        "Buy Buy Buy",
        withScreenName: "BuyPage"
      ),
      "xctest | buypage, buy buy buy",
      "getTextFeature should lowercase all text"
    )
  }

  func testPruneTree() {
    let viewTree = viewHierarchy["view"] as! [[String: Any]] // swiftlint:disable:this force_cast
    let siblings: NSMutableArray = []
    let node = (viewTree[0] as NSDictionary).mutableCopy() as! NSMutableDictionary // swiftlint:disable:this force_cast
    FeatureExtractor.pruneTree(node, siblings: siblings)

    XCTAssertEqual(self.siblings as NSArray, siblings as NSArray)
  }

  func testNonparseFeature() throws {
    let viewTreeString = try String(
      data: TypeUtility.data(
        withJSONObject: viewHierarchy["view"] as Any,
        options: .fragmentsAllowed
      ),
      encoding: .utf8
    )

    // swiftlint:disable:next force_cast
    let interactedNode = (self.interactedNode as NSDictionary).mutableCopy() as! NSMutableDictionary
    let siblings = (self.siblings as NSArray).mutableCopy() as! NSMutableArray // swiftlint:disable:this force_cast

    let nonParseFeature = FeatureExtractor.nonparseFeatures(
      interactedNode,
      siblings: siblings,
      screenname: viewHierarchy["screenname"] as! String, // swiftlint:disable:this force_cast
      viewTreeString: viewTreeString! as String // swiftlint:disable:this force_unwrapping
    )

    var nonParseFeatureArray: [Int] = []
    for idx in 0 ..< 30 {
      nonParseFeatureArray.append(Int(nonParseFeature[idx]))
    }
    XCTAssertEqual(
      nonParseFeatureArray,
      [0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
  }

  func testParseFeature() {
    let viewTree = viewHierarchy["view"] as! [[String: Any]] // swiftlint:disable:this force_cast
    let node = (viewTree[0] as NSDictionary).mutableCopy() as! NSMutableDictionary // swiftlint:disable:this force_cast
    let parseFeature = FeatureExtractor.parseFeatures(node)

    var parseFeatureArray: [Int] = []
    for idx in 0 ..< 30 {
      parseFeatureArray.append(Int(parseFeature[idx]))
    }

    XCTAssertEqual(
      parseFeatureArray,
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
  }

  func testIsButton() {
    let labelNode = [
      "classname": "UILabel",
      "classtypebitmask": "1024",
      "text": "Coffee 5",
    ]

    XCTAssertTrue(FeatureExtractor.isButton(interactedNode))
    XCTAssertFalse(FeatureExtractor.isButton(labelNode))
  }

  func testUpdateTextAndHint() {
    let buttonTextString = NSMutableString()
    let buttonHintString = NSMutableString()

    FeatureExtractor.update(interactedNode, text: buttonTextString, hint: buttonHintString)
    XCTAssertEqual(buttonTextString, "")
    XCTAssertEqual(buttonHintString, "confirm order ")
  }

  func testFoundIndicators() {
    let test1 = FeatureExtractor.foundIndicators(
      ["phone", "tel"],
      inValues: ["your phone number", "111-111-1111"]
    )
    let test2 = FeatureExtractor.foundIndicators(
      ["phone", "tel"],
      inValues: ["your email", "test@fb.com"]
    )

    XCTAssertTrue(test1)
    XCTAssertFalse(test2)
  }

  func testRegextMatch() {
    XCTAssertEqual(FeatureExtractor.regextMatch("(?i)(sign in)|login|signIn", text: "click to sign in"), 1.0)

    XCTAssertEqual(FeatureExtractor.regextMatch("(?i)(sign in)|login|signIn", text: "click to sign up"), 0.0)
  }
}
