/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class TestAppLinkEventPoster: AppLinkEventPosting {
  func postNotification(forEventName name: String, args: [String: Any]) {}
}
