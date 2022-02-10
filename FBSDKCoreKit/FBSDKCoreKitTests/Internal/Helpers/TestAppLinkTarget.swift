/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestAppLinkTarget: AppLinkTargetProtocol {

  var url: URL?
  var appStoreId: String?
  var appName: String

  init(
    url: URL?,
    appStoreId: String?,
    appName: String
  ) {
    self.url = url
    self.appStoreId = appStoreId
    self.appName = appName
  }
}
