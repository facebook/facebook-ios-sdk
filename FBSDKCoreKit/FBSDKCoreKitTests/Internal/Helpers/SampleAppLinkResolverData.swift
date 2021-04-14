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
    return [
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
    .merging(appStoreIdField(value: Values.arrayOfDictionaries)) { return $1 }
    .merging(appNameField(value: Values.arrayOfDictionaries)) { return $1 }

  static func urlField(value: Any) -> [String: Any] {
    return [
      Keys.url: value
    ]
  }
  static func appStoreIdField(value: Any) -> [String: Any] {
    return [
      Keys.appStoreID: value
    ]
  }
  static func appNameField(value: Any) -> [String: Any] {
    return [
      Keys.appName: value
    ]
  }
}
