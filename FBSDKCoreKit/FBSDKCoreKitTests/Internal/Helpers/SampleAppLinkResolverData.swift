/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum SampleAppLinkResolverData {
  enum Keys {
    static let iphone = "iphone"
    static let ios = "ios"
    static let url = "url"
    static let appStoreID = "app_store_id"
    static let appName = "app_name"
    static let web = "web"
    static let value = "_value"
    static let shouldFallback = "should_fallback"
  }

  enum Values {
    static let arrayOfDictionaries = [["foo": "bar"]]
  }

  static let urlString = "http://SampleAppLinkResolverData.com"

  static let invalid = [
    Keys.ios: [fields],
    Keys.iphone: [fields]
  ]

  static func withShouldFallback(_ shouldFallbackString: String) -> [String: Any] {
    [
      Keys.web: [
        [
          Keys.url: [
            [
              Keys.value: urlString
            ]
          ],
          Keys.shouldFallback: [
            [
              Keys.value: shouldFallbackString
            ]
          ]
        ]
      ]
    ]
  }

  static let fields = urlField(value: Values.arrayOfDictionaries)
    .merging(appStoreIdField(value: Values.arrayOfDictionaries)) { $1 }
    .merging(appNameField(value: Values.arrayOfDictionaries)) { $1 }

  static func urlField(value: Any) -> [String: Any] {
    [
      Keys.url: value
    ]
  }

  static func appStoreIdField(value: Any) -> [String: Any] {
    [
      Keys.appStoreID: value
    ]
  }

  static func appNameField(value: Any) -> [String: Any] {
    [
      Keys.appName: value
    ]
  }
}
