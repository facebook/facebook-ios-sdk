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

import FBSDKShareKit
import Foundation

/**
 A model for video content to be shared.
 */
public struct VideoShareContent: ContentProtocol, Equatable, SDKBridgedContent {
  public typealias Result = PostSharingResult

  /// Video to be shared.
  public var video: Video

  /// The photo that represents the video.
  public var previewPhoto: Photo?

  /**
   Create a `VideoShareContent` with a list of of photos to share.

   - parameter video: The video to share.
   - parameter previewPhoto: The photo that represents the video.
   */
  public init(video: Video, previewPhoto: Photo? = nil) {
    self.video = video
    self.previewPhoto = previewPhoto
  }

  //--------------------------------------
  // MARK: - ContentProtocol
  //--------------------------------------

  /**
   URL for the content being shared.

   This URL will be checked for all link meta tags for linking in platform specific ways.
   See documentation for [App Links](https://developers.facebook.com/docs/applinks/)
   */
  public var url: URL?

  /// Hashtag for the content being shared.
  public var hashtag: Hashtag?

  /**
   List of IDs for taggable people to tag with this content.

   See documentation for
   [Taggable Friends](https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  public var taggedPeopleIds: [String]?

  /// The ID for a place to tag with this content.
  public var placeId: String?

  /// A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  public var referer: String?

  // MARK: Equatable

  /**
   Compare two `VideoShareContent`s for equality.

   - parameter lhs: The first `VideoShareContent` to compare.
   - parameter rhs: The second `VideoShareContent` to compare.

   - returns: Whether or not the content are equal.
   */
  public static func == (lhs: VideoShareContent, rhs: VideoShareContent) -> Bool {
    return lhs.sdkSharingContentRepresentation.isEqual(rhs.sdkSharingContentRepresentation)
  }

  // MARK: SDKBridgedContent

  var sdkSharingContentRepresentation: FBSDKSharingContent {
    let sdkVideoContent = FBSDKShareVideoContent()
    sdkVideoContent.video = video.sdkVideoRepresentation
    sdkVideoContent.previewPhoto = previewPhoto?.sdkPhotoRepresentation
    sdkVideoContent.contentURL = url
    sdkVideoContent.hashtag = hashtag?.sdkHashtagRepresentation
    sdkVideoContent.peopleIDs = taggedPeopleIds
    sdkVideoContent.placeID = placeId
    sdkVideoContent.ref = referer
    return sdkVideoContent
  }
}
