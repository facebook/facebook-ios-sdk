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
public final class TestURLOpener: NSObject, URLOpener {

  public var capturedRequests = [SuccessBlock]()
  public var capturedURL: URL?
  public var viewController: UIViewController?
  public var wasOpenURLWithoutSVCCalled = false
  public var wasOpenURLWithSVCCalled = false

  public func open(
    _ url: URL,
    sender: URLOpening?,
    handler: @escaping SuccessBlock
  ) {
    capturedURL = url
    capturedRequests.append(handler)
    wasOpenURLWithoutSVCCalled = true
  }

  public func openURLWithSafariViewController(
    url: URL,
    sender: URLOpening,
    from fromViewController: UIViewController,
    handler: @escaping SuccessBlock
  ) {
    capturedURL = url
    capturedRequests.append(handler)
    wasOpenURLWithSVCCalled = true
    viewController = fromViewController
  }
}
