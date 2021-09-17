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

@testable import FacebookGamingServices
import XCTest

class CustomUpdateMediaTests: XCTestCase {
  // swiftlint:disable force_unwrapping
  let fakeGIF = FacebookGIF(withUrl: URL(string: "www.test.com")!)
  let fakeVideo = FacebookVideo(withUrl: URL(string: "www.test.com")!)

  func testIntilizationWithGif() throws {
    let media = try XCTUnwrap(CustomUpdateMedia(media: fakeGIF))
    let gif = try XCTUnwrap( media.gif)

    XCTAssertNotNil(media)
    XCTAssertNil(media.video)
    XCTAssertEqual(gif.url, fakeGIF.url)
  }

  func testIntilizationWithVideo() throws {
    let media = try XCTUnwrap(CustomUpdateMedia(media: fakeVideo))
    let video = try XCTUnwrap(media.video)

    XCTAssertNotNil(media)
    XCTAssertNil(media.gif)
    XCTAssertEqual(video.url, fakeVideo.url)
  }
}

extension CustomUpdateMedia {

  static func == (lhs: CustomUpdateMedia, rhs: CustomUpdateMedia) -> Bool {
    if lhs.gif != rhs.gif || lhs.video != rhs.video {
      return false
    }
    return true
  }
}
