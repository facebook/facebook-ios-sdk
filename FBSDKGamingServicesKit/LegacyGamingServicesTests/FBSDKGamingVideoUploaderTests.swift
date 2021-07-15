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

import LegacyGamingServices
import TestTools
import XCTest

class GamingVideoUploaderTests: XCTestCase {

  var videoURL = URL(string: "file://video.mp4")! // swiftlint:disable:this force_unwrapping
  lazy var configuration = createConfiguration(url: videoURL)
  let fileHandleFactory = TestFileHandleFactory()
  lazy var uploader = GamingVideoUploader(fileHandleFactory: fileHandleFactory)

  override func setUp() {
    super.setUp()

    AccessToken.current = SampleAccessTokens.validToken
  }

  func testDefaults() {
    XCTAssertTrue(
      GamingVideoUploader.shared.fileHandleFactory is FileHandleFactory,
      "Should have the expected file handle factory by default"
    )
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      ObjectIdentifier(uploader.fileHandleFactory),
      ObjectIdentifier(fileHandleFactory),
      "Should be able to create a configuration with a custom file handle factory"
    )
  }

  func testFailureWhenNoValidAccessTokenPresent() {
    AccessToken.current = nil

    var actioned = false
    GamingVideoUploader.uploadVideo(with: configuration) { _, _, error in
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorAccessTokenRequired.rawValue,
        "Expected error requiring a valid access token"
      )
      actioned = true
    }

    XCTAssertTrue(actioned)
  }

  func testBadVideoURLFails() {
    videoURL = URL(string: "file://not-a-video.mp4")! // swiftlint:disable:this force_unwrapping

    var actioned = false
    GamingVideoUploader.uploadVideo(with: configuration) { _, _, error in
      XCTAssertEqual(
        (error as NSError?)?.code,
        CoreError.errorInvalidArgument.rawValue,
        "Expected error requiring a non nil video url"
      )
      actioned = true
    }
    XCTAssertTrue(actioned)
  }

  func testCreatesFileHandle() {
    var actioned = false
    uploader.uploadVideo(with: configuration) { _, _, _ in
      XCTAssertEqual(
        self.fileHandleFactory.capturedURL,
        self.videoURL,
        "Should create a file handle with the url from the configuration"
      )
      actioned = true
    }
    XCTAssertTrue(actioned)
  }

  // MARK: - Helpers

  func createConfiguration(url: URL) -> GamingVideoUploaderConfiguration {
    GamingVideoUploaderConfiguration(videoURL: url, caption: "Cool Video")
  }
}
