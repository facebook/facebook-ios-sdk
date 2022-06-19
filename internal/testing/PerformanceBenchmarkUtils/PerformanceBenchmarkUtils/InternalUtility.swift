// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

public extension NSObject {
    @objc class func _validateFacebookReservedURLSchemes() {
        }

    @objc class func _advertiserID() -> String? {
        nil
    }

    @objc class func _appID() -> String {
        // use CoffeeShop test app id to make sure all features are ON
        return "2020399148181142"
    }

    @objc class func _getText() -> String {
        "purchase"
    }
}
