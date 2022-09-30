// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import UIKit

#if canImport(FBSDKGamingServicesKit)
import FBSDKGamingServicesKit
#endif

extension ViewController {
  func testSymbols() {
    // Just sanity checking that symbols are available
    _ = AccessToken.current
    _ = AuthenticationToken.current
    _ = [Permission.email]
    _ = SharePhoto(image: UIImage(), isUserGenerated: true)
    _ = LoginConfiguration()
    _ = LoginManager()
    _ = GamingImageUploader.self

    SomeObjCType().doStuff()
  }
}
