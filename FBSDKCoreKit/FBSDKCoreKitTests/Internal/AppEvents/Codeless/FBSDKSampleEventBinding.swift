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

@objcMembers
class FBSDKSampleEventBinding: NSObject {
  class func getSampleDictionary() -> [String: Any] { // swiftlint:disable:this function_body_length
    return [
      "event_bindings": [
        [
          "event_name": "Quantity Changed",
          "event_type": "click",
          "app_version": "1.2",
          "path": [
            [
              "class_name": "UIWindow"
            ],
            [
              "class_name": "UITabBarController"
            ],
            [
              "class_name": "UINavigationController"
            ],
            [
              "class_name": "UIViewController"
            ],
            [
              "class_name": "UIStackView"
            ],
            [
              "class_name": "UIStackView"
            ],
            [
              "class_name": "UIStepper"
            ],
          ],
        ],
        [
          "event_name": "Add To Cart",
          "event_type": "click",
          "app_version": "1.2",
          "path": [
            [
              "class_name": "UIViewController"
            ],
            [
              "class_name": "UIStackView"
            ],
            [
              "class_name": "UIButton",
              "text": "Buy",
            ],
          ],
          "parameters": [
            [
              "parameter_name": "price",
              "path_type": "relative",
              "path": [
                [
                  "class_name": ".."
                ],
                [
                  "class_name": "UILabel",
                  "index": 2,
                ]
              ]
            ]
          ]
        ],
        [
          "event_name": "Purchase",
          "event_type": "click",
          "app_version": "1.2",
          "path": [
            [
              "class_name": "UIWindow"
            ],
            [
              "class_name": "UITabBarController"
            ],
            [
              "class_name": "UINavigationController"
            ],
            [
              "class_name": "UIViewController"
            ],
            [
              "class_name": "UIStackView"
            ],
            [
              "class_name": "UIButton",
              "text": "Confirm",
            ],
          ],
          "parameters": [
            [
              "parameter_name": "price",
              "path_type": "relative",
              "path": [
                [
                  "class_name": ".."
                ],
                [
                  "class_name": "UIStackView"
                ],
                [
                  "class_name": "UILabel",
                  "index": 0,
                ],
              ],
            ],
            [
              "parameter_name": "action",
              "path_type": "relative",
              "path": [
                [
                  "class_name": "."
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  }
}
