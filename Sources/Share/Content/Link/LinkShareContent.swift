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
 A model for status and link content to be shared
 */
public struct LinkShareContent: ContentProtocol {
  public typealias Result = PostSharingResult

  /**
   The title to display for this link.

   This value may be discarded for specially handled links (ex: iTunes URLs).
   */
  @available(*, deprecated, message: "`title` is deprecated from Graph API 2.9")
  public var title: String?

  /**
   The description of the link.

   If not specified, this field is automatically populated by information scraped from the contentURL,
   typically the title of the page. This value may be discarded for specially handled links (ex: iTunes URLs).
   */
  @available(*, deprecated, message: "`description` is deprecated from Graph API 2.9")
  public var description: String?

  /**
   Some quote text of the link.

   If specified, the quote text will render with custom styling on top of the link.
   */
  public var quote: String?

  /// The URL of a picture to attach to this content.
  @available(*, deprecated, message: "`imageURL` is deprecated from Graph API 2.9")
  public var imageURL: URL?

  /**
   Create link share content.

   - parameter url:         The URL being shared.
   - parameter title:       Optional title to display for this link.
   - parameter description: Optional description of the link.
   - parameter quote:       Optional quote text of the link.
   - parameter imageURL:    OPtional image URL of a picture to attach.
   */
  @available(*, deprecated, message: "`title`, `description`, `imageURL` are deprecated from Graph API 2.9")
  public init(url: URL,
              title: String? = nil,
              description: String? = nil,
              quote: String? = nil,
              imageURL: URL? = nil) {
    self.url = url
    self.title = title
    self.description = description
    self.quote = quote
    self.imageURL = imageURL
  }
  
  /**
   Create link share content.
   
   - parameter url:         The URL being shared.
   - parameter quote:       Optional quote text of the link.
   */
  public init(url: URL,
              quote: String? = nil) {
    self.url = url
    self.quote = quote
  }

  //--------------------------------------
  // MARK - Content
  //--------------------------------------

  /**
   URL for the content being shared.

   This URL will be checked for all link meta tags for linking in platform specific ways.
   See documentation for App Links (https://developers.facebook.com/docs/applinks/).
   */
  public var url: URL?

  /// Hashtag for the content being shared.
  public var hashtag: Hashtag?

  /**
   List of IDs for taggable people to tag with this content.

   See documentation for Taggable Friends (https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  public var taggedPeopleIds: [String]?

  /// The ID for a place to tag with this content.
  public var placeId: String?

  ///  A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  public var referer: String?
}

extension LinkShareContent: Equatable {

  /**
   Compares two `LinkContent`s for equality.

   - parameter lhs: One content to compare.
   - parameter rhs: The other content to compare to.

   - returns: Whether or not the content are equivalent.
   */
  public static func == (lhs: LinkShareContent, rhs: LinkShareContent) -> Bool {
    return lhs.sdkSharingContentRepresentation.isEqual(rhs.sdkSharingContentRepresentation)
  }
}

extension LinkShareContent: SDKBridgedContent {
  internal var sdkSharingContentRepresentation: FBSDKSharingContent {
    let content = FBSDKShareLinkContent()
    content.quote = self.quote
    content.contentURL = self.url
    content.hashtag = self.hashtag?.sdkHashtagRepresentation
    content.peopleIDs = self.taggedPeopleIds
    content.placeID = self.placeId
    content.ref = self.referer
    return content
  }
}
