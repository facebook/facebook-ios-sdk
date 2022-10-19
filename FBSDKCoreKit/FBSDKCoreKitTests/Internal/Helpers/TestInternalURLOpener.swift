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
public final class TestInternalURLOpener: NSObject, _InternalURLOpener {
  var capturedOpenURL: URL?
  var capturedCanOpenURL: URL?
  var openURLStubs = [URL: Bool]()
  public var openAlwaysSucceeds = false
  var canOpenURL: Bool
  var capturedOpenURLCompletion: ((Bool) -> Void)?

  init(canOpenURL: Bool = false) {
    self.canOpenURL = canOpenURL
  }

  func stubOpen(url: URL, success: Bool) {
    openURLStubs[url] = success
  }

  public func canOpen(_ url: URL) -> Bool {
    capturedCanOpenURL = url
    return canOpenURL
  }

  public func open(_ url: URL) -> Bool {
    capturedOpenURL = url

    guard !openAlwaysSucceeds else {
      return true
    }

    guard let didOpen = openURLStubs[url] else {
      fatalError("Must stub whether \(url.absoluteString) can be opened")
    }

    return didOpen
  }

  public func open(
    _ url: URL,
    options: [UIApplication.OpenExternalURLOptionsKey: Any],
    completionHandler completion: ((Bool) -> Void)?
  ) {
    capturedOpenURL = url
    capturedOpenURLCompletion = completion
  }
}
