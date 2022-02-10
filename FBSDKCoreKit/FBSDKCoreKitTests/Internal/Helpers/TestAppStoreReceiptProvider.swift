/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
final class TestAppStoreReceiptProvider: AppStoreReceiptProviding {
  var wasAppStoreReceiptURLRead = false
  var stubbedURL: URL?

  var appStoreReceiptURL: URL? {
    wasAppStoreReceiptURLRead = true
    return stubbedURL
  }
}
