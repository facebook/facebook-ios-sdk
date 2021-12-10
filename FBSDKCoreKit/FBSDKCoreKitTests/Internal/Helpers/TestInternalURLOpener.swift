/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
class TestInternalURLOpener: NSObject, InternalURLOpener {
  var capturedOpenUrl: URL?
  var capturedCanOpenUrl: URL?
  var openUrlStubs = [URL: Bool]()
  var canOpenUrl: Bool
  var capturedOpenUrlCompletion: ((Bool) -> Void)?

  init(canOpenUrl: Bool = false) {
    self.canOpenUrl = canOpenUrl
  }

  func stubOpen(url: URL, success: Bool) {
    openUrlStubs[url] = success
  }

  func canOpen(_ url: URL) -> Bool {
    capturedCanOpenUrl = url
    return canOpenUrl
  }

  func open(_ url: URL) -> Bool {
    capturedOpenUrl = url
    guard let didOpen = openUrlStubs[url] else {
      fatalError("Must stub whether \(url.absoluteString) can be opened")
    }
    return didOpen
  }

  func open(
    _ url: URL,
    options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
    completionHandler completion: ((Bool) -> Void)?
  ) {
    capturedOpenUrl = url
    capturedOpenUrlCompletion = completion
  }
}
