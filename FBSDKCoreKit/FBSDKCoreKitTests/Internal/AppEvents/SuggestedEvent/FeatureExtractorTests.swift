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

class FeatureExtractorTests: XCTestCase {
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
                            "text": "Order Summary"
                          ],
                          [
                            "classname": "UIStackView",
                            "classtypebitmask": "0",
                            "childviews": [
                              [
                                "classname": "UIView",
                                "classtypebitmask": "0"
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1024",
                                "text": "Coffee 5"
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "Price: $5.99"
                              ]
                            ]
                          ],
                          [
                            "classname": "UIStackView",
                            "classtypebitmask": "0",
                            "childviews": [
                              [
                                "classname": "UIView",
                                "classtypebitmask": "0"
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1024",
                                "text": "Quantity"
                              ],
                              [
                                "classname": "UILabel",
                                "classtypebitmask": "1"
                              ]
                            ]
                          ],
                          [
                            "classname": "UITextField",
                            "classtypebitmask": "2056",
                            "hint": "Credit Card Credit Card"
                          ],
                          [
                            "classname": "UITextField",
                            "classtypebitmask": "2056",
                            "hint": "Shipping Address Shipping Address"
                          ],
                          [
                            "classname": "UIButton",
                            "classtypebitmask": "24",
                            "is_interacted": 1,
                            "hint": "Confirm Order"
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ],
              [
                "classname": "UITabBar",
                "classtypebitmask": "0"
              ]
            ]
          ]
        ]
      ]
    ]
  ]

  let interactedNode: [String: Any] = [
    "classname": "UIButton",
    "classtypebitmask": "24",
    "is_interacted": 1,
    "hint": "Confirm Order"
  ]

  let siblings = [
    [
      "classname": "UILabel",
      "classtypebitmask": "1024",
      "text": "Order Summary"
    ],
    [
      "classname": "UIStackView",
      "classtypebitmask": "0",
      "childviews": [
        [
          "classname": "UIView",
          "classtypebitmask": "0"
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1024",
          "text": "Coffee 5"
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "Price: $5.99"
        ]
      ]
    ],
    [
      "classname": "UIStackView",
      "classtypebitmask": "0",
      "childviews": [
        [
          "classname": "UIView",
          "classtypebitmask": "0"
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1024",
          "text": "Quantity"
        ],
        [
          "classname": "UILabel",
          "classtypebitmask": "1"
        ]
      ]
    ],
    [
      "classname": "UITextField",
      "classtypebitmask": "2056",
      "hint": "Credit Card Credit Card"
    ],
    [
      "classname": "UITextField",
      "classtypebitmask": "2056",
      "hint": "Shipping Address Shipping Address"
    ],
    [
      "classname": "UIButton",
      "classtypebitmask": "24",
      "is_interacted": 1,
      "hint": "Confirm Order"
    ]
  ]

  let modelManager = TestOnDeviceMLModelManager()

  override func setUpWithError() throws { // swiftlint:disable:this overridden_super_call
    super.setUp()

    let bundle = Bundle(for: FeatureExtractorTests.self)
    let fileURL = bundle.path(
      forResource: "FBSDKTextClassifyRules",
      ofType: "json"
    ) ?? ""
    if !fileURL.isEmpty {
      let data = try XCTUnwrap(NSData(contentsOfFile: fileURL, options: .mappedIfSafe))
      self.rules = try TypeUtility.jsonObject(
        with: data as Data
      ) as! [String: Any] // swiftlint:disable:this force_cast
    }
    FeatureExtractor.configureWithRules(self.modelManager)
    self.modelManager.rulesForKey = self.rules

    FeatureExtractor.loadRules(forKey: "MTML")
  }

  override func tearDown() {
    super.tearDown()

    FeatureExtractor.reset()
  }

  func testGetDenseFeature() {
    let denseFeature = FeatureExtractor.getDenseFeatures(
      self.viewHierarchy
    )! // swiftlint:disable:this force_unwrapping

    var denseFeatureArray: [Int] = []
    for feature in 0..<30 {
      denseFeatureArray.append(Int(denseFeature[feature]))
    }
    XCTAssertEqual(
      denseFeatureArray,
      [0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
  }

  func testGetDenseFeatureParsing() {
    for _ in 0..<100 {
      FeatureExtractor.getDenseFeatures(
        Fuzzer.randomize(json: self.viewHierarchy) as! [String: Any] // swiftlint:disable:this force_cast
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
    let viewTree = self.viewHierarchy["view"] as! [[String: Any]] // swiftlint:disable:this force_cast
    let siblings: NSMutableArray = []
    let node = (viewTree[0] as NSDictionary).mutableCopy() as! NSMutableDictionary // swiftlint:disable:this force_cast
    FeatureExtractor.pruneTree(node, siblings: siblings)

    XCTAssertEqual(self.siblings as NSArray, siblings as NSArray)
  }

  func testNonparseFeature() throws {
    let viewTreeString = try String(
      data: TypeUtility.data(
        withJSONObject: self.viewHierarchy["view"] as Any,
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
      screenname: self.viewHierarchy["screenname"] as! String, // swiftlint:disable:this force_cast
      viewTreeString: viewTreeString! as String // swiftlint:disable:this force_unwrapping
    )

    var nonParseFeatureArray: [Int] = []
    for idx in 0..<30 {
      nonParseFeatureArray.append(Int(nonParseFeature[idx]))
    }
    XCTAssertEqual(
      nonParseFeatureArray,
      [0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    )
  }

  func testParseFeature() {
    let viewTree = self.viewHierarchy["view"] as! [[String: Any]] // swiftlint:disable:this force_cast
    let node = (viewTree[0] as NSDictionary).mutableCopy() as! NSMutableDictionary // swiftlint:disable:this force_cast
    let parseFeature = FeatureExtractor.parseFeatures(node)

    var parseFeatureArray: [Int] = []
    for idx in 0..<30 {
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
      "text": "Coffee 5"
    ]

    XCTAssertTrue(FeatureExtractor.isButton(self.interactedNode))
    XCTAssertFalse(FeatureExtractor.isButton(labelNode))
  }

  func testUpdateTextAndHint() {
    let buttonTextString = NSMutableString()
    let buttonHintString = NSMutableString()

    FeatureExtractor.update(self.interactedNode, text: buttonTextString, hint: buttonHintString)
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
