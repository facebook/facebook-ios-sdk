// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

extension NSObject {
  @objc public class func _validateFacebookReservedURLSchemes() {}

  @objc public class func _advertiserID() -> String? {
    nil
  }

  @objc public class func _appID() -> String {
    // use CoffeeShop test app id to make sure all features are ON
    return "2020399148181142"
  }

  @objc public class func _getText() -> String {
    "purchase"
  }
}
