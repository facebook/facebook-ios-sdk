// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

/**
 Represents a single application event that can be logged to Facebook Analytics.
 */
public struct AppEvent: AppEventLoggable {
  public typealias ParametersDictionary = [AppEventParameterName : AppEventParameterValueType]

  /// Name of the application event.
  public let name: AppEventName

  /// Arbitrary parameter dictionary of characteristics of an event.
  public var parameters: ParametersDictionary

  /**
   Amount to be aggregated into all events of this eventName.
   App Insights will report the cumulative and average value of this amount.
   */
  public var valueToSum: Double?

  /**
   Creates an app event.

   - parameter name:       App event name.
   - parameter parameters: Parameters dictionary. Default: empty.
   - parameter valueToSum: Optional value to sum. Default: `nil`.
   */
  public init(name: AppEventName, parameters: ParametersDictionary = [:], valueToSum: Double? = nil) {
    self.name = name
    self.parameters = parameters
    self.valueToSum = valueToSum
  }
}

extension AppEvent {
  /**
   Creates an app event.

   - parameter name:       String representation of app event name.
   - parameter parameters: Parameters dictionary. Default: empty.
   - parameter valueToSum: Optional value to sum. Default: `nil`.
   */
  public init(name: String, parameters: ParametersDictionary = [:], valueToSum: Double? = nil) {
    self.init(name: AppEventName(name), parameters: parameters, valueToSum: valueToSum)
  }
}

/**
 Protocol that describes a single application event that can be logged to Facebook Analytics.
 */
public protocol AppEventLoggable {
  /// Name of the application event.
  var name: AppEventName { get }
  /// Arbitrary parameter dictionary of characteristics of an event.
  var parameters: AppEvent.ParametersDictionary { get }
  /// Amount to be aggregated into all events of this eventName.
  var valueToSum: Double? { get }
}

/**
 Conforming types that can be logged as a parameter value of `AppEventLoggable`.
 By default implemented for `NSNumber`, `String`, `IntegerLiteralType` and `FloatLiteralType`.
 Should only return either a `String` or `NSNumber`.
 */
public protocol AppEventParameterValueType {
  /// Object value. Can be either `NSNumber` or `String`.
  var appEventParameterValue: AnyObject { get }
}

extension NSNumber: AppEventParameterValueType {
  /// An object representation of `self`, suitable for parameter value of `AppEventLoggable`.
  public var appEventParameterValue: AnyObject {
    return self
  }
}

extension IntegerLiteralType: AppEventParameterValueType {
  /// An object representation of `self`, suitable for parameter value of `AppEventLoggable`.
  public var appEventParameterValue: AnyObject {
    return self as NSNumber
  }
}

extension FloatLiteralType: AppEventParameterValueType {
  /// An object representation of `self`, suitable for parameter value of `AppEventLoggable`.
  public var appEventParameterValue: AnyObject {
    return self as NSNumber
  }
}

extension String: AppEventParameterValueType {
  /// An object representation of `self`, suitable for parameter value of `AppEventLoggable`.
  public var appEventParameterValue: AnyObject {
    return self
  }
}
