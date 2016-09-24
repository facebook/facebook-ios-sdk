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
 A model for Open Graph content to be shared.
 */
public struct OpenGraphShareContent {
  public typealias Result = PostSharingResult

  /// The Open Graph action to be shared.
  public var action: OpenGraphAction?

  /// Property name that points to the primary Open Graph Object in the action. This is used for rendering the preview of the share.
  public var previewPropertyName: OpenGraphPropertyName?

  /**
   Create a new OpenGraphShareContent.

   - parameter action:              The action to be shared.
   - parameter previewPropertyName: Property name that points to the primary Open Graph Object in the action.
   */
  public init(action: OpenGraphAction? = nil, previewPropertyName: OpenGraphPropertyName? = nil) {
    self.action = action
    self.previewPropertyName = previewPropertyName
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

   See documentation for [Taggable Friends](https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  public var taggedPeopleIds: [String]?

  /// The ID for a place to tag with this content.
  public var placeId: String?

  ///  A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  public var referer: String?
}

extension OpenGraphShareContent: Equatable {
  /**
   Compares two `OpenGraphContent`s for equality.

   - parameter lhs: The first content to compare.
   - parameter rhs: The second content to comare.

   - returns: Whether or not the content are equal.
   */
  public static func == (lhs: OpenGraphShareContent, rhs: OpenGraphShareContent) -> Bool {
    return lhs.sdkSharingContentRepresentation.isEqual(rhs.sdkSharingContentRepresentation)
  }
}

extension OpenGraphShareContent: SDKBridgedContent {
  internal var sdkSharingContentRepresentation: FBSDKSharingContent {
    let sdkContent = FBSDKShareOpenGraphContent()
    sdkContent.action = action?.sdkActionRepresentation
    sdkContent.previewPropertyName = previewPropertyName?.rawValue
    sdkContent.contentURL = url
    sdkContent.hashtag = hashtag?.sdkHashtagRepresentation
    sdkContent.peopleIDs = taggedPeopleIds
    sdkContent.placeID = placeId
    sdkContent.ref = referer
    return sdkContent
  }
}
