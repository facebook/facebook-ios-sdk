/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
public final class TestBridgeAPIRequestOpener: NSObject, BridgeAPIRequestOpening {

  public var capturedURL: URL?
  public var capturedHandler: SuccessBlock?
  public var capturedRequest: BridgeAPIRequestProtocol?
  public var capturedUseSafariViewController: Bool? // swiftlint:disable:this discouraged_optional_boolean
  public var capturedFromViewController: UIViewController?
  public var capturedCompletionBlock: BridgeAPIResponseBlock?
  public var openURLWithSFVCCount = 0

  public func open(
    _ request: BridgeAPIRequestProtocol,
    useSafariViewController: Bool,
    from fromViewController: UIViewController?,
    completionBlock: @escaping BridgeAPIResponseBlock
  ) {
    capturedRequest = request
    capturedUseSafariViewController = useSafariViewController
    capturedFromViewController = fromViewController
    capturedCompletionBlock = completionBlock
  }

  public func openURLWithSafariViewController(
    url: URL,
    sender: URLOpening?,
    from fromViewController: UIViewController?,
    handler: @escaping SuccessBlock
  ) {
    openURLWithSFVCCount += 1
    handler(true, nil)
  }

  public func open(_ url: URL, sender: URLOpening?, handler: @escaping SuccessBlock) {
    capturedURL = url
    capturedHandler = handler
  }
}
