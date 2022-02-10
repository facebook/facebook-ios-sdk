/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestDeviceInformationProvider: DeviceInformationProviding {
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
