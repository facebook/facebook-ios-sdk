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
import FBSDKShareKit

/**
 A video for sharing.
 */
public struct Video {

  /// The file URL to the video.
  public var url: URL

  /**
   Build a new video with a video URL and preivew photo.

   - parameter url: The file URL to the video.
   */
  public init(url: URL) {
    self.url = url
  }
}

extension Video: Equatable {
  /**
   Compare two `Video`s for equality.

   - parameter lhs: The first `Video` to compare.
   - parameter rhs: The second `Video` to compare.

   - returns: Whether or not the videos are equal.
   */
  public static func == (lhs: Video, rhs: Video) -> Bool {
    return lhs.sdkVideoRepresentation == rhs.sdkVideoRepresentation
  }
}

extension Video {
  internal var sdkVideoRepresentation: FBSDKShareVideo {
    let sdkVideo = FBSDKShareVideo()
    sdkVideo.videoURL = url

    return sdkVideo
  }

  internal init?(sdkVideoRepresentation: FBSDKShareVideo) {
    guard let url = sdkVideoRepresentation.videoURL else {
      return nil
    }
    self.url = url
  }
}
