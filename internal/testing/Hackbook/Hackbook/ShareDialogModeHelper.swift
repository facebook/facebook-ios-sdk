// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKShareKit
import Foundation

@objcMembers
@objc final class ShareDialogModeHelper: NSObject {
  @objc(descriptionForMode:)
  class func description(for mode: ShareDialog.Mode) -> String {
    mode.description
  }
}
