/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

final class TestIAPEventResolverDelegate: NSObject, IAPEventResolverDelegate {
  var capturedNewEvent: IAPEvent?
  var capturedRestoredEvent: IAPEvent?
  var capturedFailedEvent: IAPEvent?
  var capturedInitiatedCheckoutEvent: IAPEvent?

  func didResolveNew(event: IAPEvent) {
    capturedNewEvent = event
  }

  func didResolveRestored(event: IAPEvent) {
    capturedRestoredEvent = event
  }

  func didResolveFailed(event: IAPEvent) {
    capturedFailedEvent = event
  }

  func didResolveInitiatedCheckout(event: IAPEvent) {
    capturedInitiatedCheckoutEvent = event
  }

  func reset() {
    capturedNewEvent = nil
    capturedRestoredEvent = nil
    capturedFailedEvent = nil
    capturedInitiatedCheckoutEvent = nil
  }
}
