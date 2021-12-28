/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class SampleRawRemoteEventBindings: NSObject {

  static var sampleDictionary: [String: Any] {
    [
      "event_bindings": bindings
    ]
  }

  static var bindings: [[String: Any]] {
    [
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
  }

  static func rawBinding(name: String) -> [String: Any] {
    [
      "event_name": name,
      "event_type": "click",
      "app_version": "1.2",
      "path": [
        [
          "class_name": "UIWindow"
        ]
      ]
    ]
  }
}
