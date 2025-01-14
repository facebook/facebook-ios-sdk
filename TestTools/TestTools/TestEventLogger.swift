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
open class TestEventLogger: NSObject, EventLogging {
  // swiftlint:disable:this prefer_final_classes
  public var flushCallCount = 0
  public var flushBehavior: AppEvents.FlushBehavior = .auto
  public var capturedEventName: AppEvents.Name?
  public var capturedParameters: [AppEvents.ParameterName: Any]?
  public var capturedIsImplicitlyLogged = false
  public var capturedAccessToken: AccessToken?
  public var capturedValueToSum: Double?
  public var capturedFlushReason: AppEvents.FlushReason?
  public var capturedEvents: [EventStructForTests] = []
  public var capturedOperationalParameters: [AppOperationalDataType: [String: Any]]?

  public func flush(for flushReason: AppEvents.FlushReason) {
    flushCallCount += 1
    capturedFlushReason = flushReason
  }

  public func logEvent(_ eventName: AppEvents.Name, parameters: [AppEvents.ParameterName: Any]?) {
    capturedEventName = eventName
    capturedParameters = parameters
  }

  public func logEvent(
    _ eventName: AppEvents.Name,
    valueToSum: Double,
    parameters: [AppEvents.ParameterName: Any]?
  ) {
    capturedEventName = eventName
    capturedValueToSum = valueToSum
    capturedParameters = parameters
  }

  public func logInternalEvent(_ eventName: AppEvents.Name, isImplicitlyLogged: Bool) {
    capturedEventName = eventName
    capturedIsImplicitlyLogged = isImplicitlyLogged
  }

  public func logInternalEvent(
    _ eventName: AppEvents.Name,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool
  ) {
    capturedEventName = eventName
    capturedParameters = parameters
    capturedIsImplicitlyLogged = isImplicitlyLogged
  }

  public func logInternalEvent(
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

  public func logInternalEvent(
    _ eventName: AppEvents.Name,
    valueToSum: Double,
    isImplicitlyLogged: Bool
  ) {
    capturedEventName = eventName
  }

  public func logEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    accessToken: AccessToken?
  ) {
    capturedEventName = eventName
    capturedValueToSum = valueToSum?.doubleValue
    capturedParameters = parameters
  }

  // swiftlint:disable:next function_parameter_count
  public func doLogEvent(
    _ eventName: AppEvents.Name,
    valueToSum: NSNumber?,
    parameters: [AppEvents.ParameterName: Any]?,
    isImplicitlyLogged: Bool,
    accessToken: AccessToken?,
    operationalParameters: [AppOperationalDataType: [String: Any]]?
  ) {
    capturedEventName = eventName
    capturedValueToSum = valueToSum?.doubleValue
    capturedParameters = parameters
    capturedIsImplicitlyLogged = isImplicitlyLogged
    capturedAccessToken = accessToken
    capturedOperationalParameters = operationalParameters
    let event = EventStructForTests(
      eventName: eventName,
      valueToSum: valueToSum,
      parameters: parameters,
      isImplicitEvent: isImplicitlyLogged,
      accessToken: accessToken,
      operationalParameters: operationalParameters
    )
    capturedEvents.append(event)
  }
}

public struct EventStructForTests {
  public let eventName: AppEvents.Name
  public let valueToSum: NSNumber?
  public let parameters: [AppEvents.ParameterName: Any]?
  public let isImplicitEvent: Bool
  public let accessToken: AccessToken?
  public let operationalParameters: [AppOperationalDataType: [String: Any]]?
}
