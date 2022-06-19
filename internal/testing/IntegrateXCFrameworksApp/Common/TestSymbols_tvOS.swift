// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import UIKit

extension ViewController {
    func testSymbols() {
        // Just sanity checking that symbols are available
        _ = AccessToken.current
        _ = DeviceLoginManager(permissions: ["email"], enableSmartLogin: true)
        _ = SharePhoto(image: UIImage(), isUserGenerated: true)
    }
}
