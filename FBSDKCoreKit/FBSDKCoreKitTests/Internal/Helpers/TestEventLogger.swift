/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import Foundation

@objcMembers
class TestEventLogger: NSObject, EventLogging { // swiftlint:disable:this prefer_final_classes
  var flushCallCount = 0
  var flushBehavior: AppEvents.FlushBehavior = .auto
  var capturedEventName: AppEvents.Name?
  var capturedParameters: [AppEvents.ParameterName: Any]?
  var capturedIsImplicitlyLogged = false
  var capturedAccessToken: AccessToken?
  var capturedValueToSum: Double?
  var capturedFlushReason: AppEvents.FlushReason?

  func flush(for flushReason: AppEvents.FlushReason) {
    flushCallCount += 1
    capturedFlushReason = flushReason
  }

  func logEvent(_ eventName: AppEvents.Name, parameters: [AppEvents.ParameterName: Any]?) {
    capturedEventName = eventName
    capturedParameters = parameters
  }

  func logEvent(
    _ eventName: AppEvents.Name,
    valueToSum: Double,
    parameters: [AppEvents.ParameterName: Any]?
  ) {
    capturedEventName = eventName
    capturedValueToSum = valueToSum
    capturedParameters = parameters
  }

  func logInternalEvent(_ eventName: AppEvents.Name, isImplicitlyLogged: Bool) {
    capturedEventName = eventName
    capturedIsImplicitlyLogged = isImplicitlyLogged
  }

  func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool
  ) {
    capturedEventName = eventName
    capturedParameters = parameters
    capturedIsImplicitlyLogged = isImplicitlyLogged
  }

  func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool,
    accessToken: AccessToken?
  ) {
    capturedEventName = eventName
    capturedParameters = parameters
    capturedIsImplicitlyLogged = isImplicitlyLogged
    capturedAccessToken = accessToken
  }

  func logInternalEvent(
    _ eventName: AppEvents.Name,
    valueToSum: Double,
    isImplicitlyLogged: Bool
  ) {
    capturedEventName = eventName
  }
}
