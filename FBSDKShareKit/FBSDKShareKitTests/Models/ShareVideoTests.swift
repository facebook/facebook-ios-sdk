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

import FBSDKCoreKit
import XCTest

class ShareVideoTests: XCTestCase {

  func testImageProperties() {
    guard let video = ShareModelTestUtility.videoWithPreviewPhoto() else {
      XCTFail("unable to get a 'ShareVideo'")
      return
    }

    XCTAssertEqual(video.videoURL, ShareModelTestUtility.videoURL())
    XCTAssertEqual(video.previewPhoto, ShareModelTestUtility.photoWithImageURL())
  }

  func testCopy() throws {
    guard
      let video = ShareModelTestUtility.video(),
      let videoCopy = video.copy() as? ShareVideo
    else {
      XCTFail("unable to get a 'ShareVideo' or make a copy")
      return
    }

    XCTAssertEqual(videoCopy, video)
  }

  func testCoding() throws {
    guard
      let video = ShareModelTestUtility.videoWithPreviewPhoto()
    else {
      XCTFail("unable to get a 'ShareVideo'")
      return
    }

    var unarchivedContent: ShareVideo?
    var data: Data

    if #available(iOS 11.0, *) {
      // NSKeyedUnarchiver.unarchiveObject(with:) is deprecated in iOS 12. This new version is available from iOS 11.
      data = try NSKeyedArchiver.archivedData(withRootObject: video, requiringSecureCoding: true)
      unarchivedContent = try NSKeyedUnarchiver.unarchivedObject(ofClass: ShareVideo.self, from: data)
    } else {
      data = NSKeyedArchiver.archivedData(withRootObject: video)
      unarchivedContent = NSKeyedUnarchiver.unarchiveObject(with: data) as? ShareVideo
    }

    guard let unarchivedContent = unarchivedContent else {
      XCTFail("Unable to unarchive or casting to 'ShareVideo' failed")
      return
    }

    XCTAssertEqual(unarchivedContent, video)
  }
}
