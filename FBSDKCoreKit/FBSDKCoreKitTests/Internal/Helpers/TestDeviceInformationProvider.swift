/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestDeviceInformationProvider: _DeviceInformationProviding {
  var carrierName: String? = "NoCarrier"

  var timeZoneAbbrev: String? = ""

  var remainingDiskSpaceGB: UInt64 = 0

  var timeZoneName: String? = ""

  var bundleIdentifier: String? = ""

  var longVersion: String? = "1.0.1"

  var shortVersion: String? = "1.0.1"

  var sysVersion: String? = "16.0.1"

  var machine: String? = "iphone12"

  var language: String? = "en_US"

  var totalDiskSpaceGB: UInt64 = 0

  var coreCount: UInt64 = 0

  var width: CGFloat = 0.0

  var height: CGFloat = 0.0

  var density: CGFloat = 0.0

  var storageKey = "storageKey"
  var stubbedEncodedDeviceInfo: String?
  var encodedDeviceInfoWasCalled = false

  init(stubbedEncodedDeviceInfo: String? = nil) {
    self.stubbedEncodedDeviceInfo = stubbedEncodedDeviceInfo
  }

  var encodedDeviceInfo: String? {
    encodedDeviceInfoWasCalled = true

    return stubbedEncodedDeviceInfo
  }
}
