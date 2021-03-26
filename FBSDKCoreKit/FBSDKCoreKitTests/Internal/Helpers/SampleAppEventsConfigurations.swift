// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

@objcMembers
class SampleAppEventsConfigurations: NSObject {

  static let `default` = AppEventsConfiguration.default()

  static var valid: AppEventsConfiguration {
    return create(
      defaultATEStatus: AppEventsUtility.AdvertisingTrackingStatus.unspecified,
      advertiserIDCollectionEnabled: true,
      eventCollectionEnabled: false
    )
  }

  static func create(
    defaultATEStatus status: AppEventsUtility.AdvertisingTrackingStatus
  ) -> AppEventsConfiguration {
    return create(
      defaultATEStatus: status,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled
    )
  }

  static func create(
    advertiserIDCollectionEnabled: Bool
  ) -> AppEventsConfiguration {
    return create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled,
      eventCollectionEnabled: self.default.eventCollectionEnabled
    )
  }

  static func create(
    eventCollectionEnabled: Bool
  ) -> AppEventsConfiguration {
    return create(
      defaultATEStatus: self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled
    )
  }

  static func create(
    defaultATEStatus: AppEventsUtility.AdvertisingTrackingStatus?,
    advertiserIDCollectionEnabled: Bool?,
    eventCollectionEnabled: Bool?
  ) -> AppEventsConfiguration {
    return AppEventsConfiguration(
      defaultATEStatus: defaultATEStatus ?? self.default.defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled ?? self.default.advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled ?? self.default.eventCollectionEnabled
    )
  }

  static func create(
    defaultATEStatus: AppEventsUtility.AdvertisingTrackingStatus,
    advertiserIDCollectionEnabled: Bool,
    eventCollectionEnabled: Bool
  ) -> AppEventsConfiguration {
    return AppEventsConfiguration(
      defaultATEStatus: defaultATEStatus,
      advertiserIDCollectionEnabled: advertiserIDCollectionEnabled,
      eventCollectionEnabled: eventCollectionEnabled
    )
  }
}
