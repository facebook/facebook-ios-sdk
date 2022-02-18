/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

@objc(FBSDKShareInternalURLOpening)
protocol ShareInternalURLOpening {
  func canOpenURL(_ url: URL) -> Bool
}

extension UIApplication: ShareInternalURLOpening {}
