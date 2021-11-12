/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class TestDeviceInformationProvider: DeviceInformationProviding {
  var storageKey = "storageKey"
  var stubbedEncodedDeviceInfo: String
  var encodedDeviceInfoWasCalled = false

  init(stubbedEncodedDeviceInfo: String = "") {
    self.stubbedEncodedDeviceInfo = stubbedEncodedDeviceInfo
  }

  var encodedDeviceInfo: String {
    encodedDeviceInfoWasCalled = true

    return stubbedEncodedDeviceInfo
  }
}
