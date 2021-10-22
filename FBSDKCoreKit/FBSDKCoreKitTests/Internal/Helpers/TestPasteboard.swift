/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

@objcMembers
class TestPasteboard: NSObject, Pasteboard {
  var name = "pasteboard"
  var stubbedData: Data?
  var capturedData: Data?
  var capturedPasteboardType: String?
  var _isGeneralPasteboard = false // swiftlint:disable:this identifier_name

  func data(forPasteboardType pasteboardType: String) -> Data? {
    stubbedData
  }

  func setData(_ data: Data, forPasteboardType pasteboardType: String) {
    capturedData = data
    capturedPasteboardType = pasteboardType
  }
}
