/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import XCTest

final class GamingVideoUploaderConfigurationTests: XCTestCase {

  let url = URL(string: "file://video.mp4")! // swiftlint:disable:this force_unwrapping
  let caption = "Cool Video"
  lazy var configuration = GamingVideoUploaderConfiguration(videoURL: url, caption: caption)

  func testValuesAreSavedToConfig() {
    XCTAssertEqual(configuration.caption, caption)
    XCTAssertEqual(configuration.videoURL, url)
  }
}
