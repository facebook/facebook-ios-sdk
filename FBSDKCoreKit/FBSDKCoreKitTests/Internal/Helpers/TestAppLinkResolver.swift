/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestAppLinkResolver: NSObject, AppLinkResolving {
  var capturedUrl: URL?
  var capturedCompletion: AppLinkBlock?

  func appLink(from url: URL, handler: @escaping AppLinkBlock) {
    capturedUrl = url
    capturedCompletion = handler
  }
}
