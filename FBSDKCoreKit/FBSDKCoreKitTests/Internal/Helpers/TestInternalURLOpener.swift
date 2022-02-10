/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
final class TestInternalURLOpener: NSObject, InternalURLOpener {
  var capturedOpenURL: URL?
  var capturedCanOpenURL: URL?
  var openURLStubs = [URL: Bool]()
  var canOpenURL: Bool
  var capturedOpenURLCompletion: ((Bool) -> Void)?

  init(canOpenURL: Bool = false) {
    self.canOpenURL = canOpenURL
  }

  func stubOpen(url: URL, success: Bool) {
    openURLStubs[url] = success
  }

  func canOpen(_ url: URL) -> Bool {
    capturedCanOpenURL = url
    return canOpenURL
  }

  func open(_ url: URL) -> Bool {
    capturedOpenURL = url
    guard let didOpen = openURLStubs[url] else {
      fatalError("Must stub whether \(url.absoluteString) can be opened")
    }
    return didOpen
  }

  func open(
    _ url: URL,
    options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
    completionHandler completion: ((Bool) -> Void)?
  ) {
    capturedOpenURL = url
    capturedOpenURLCompletion = completion
  }
}
