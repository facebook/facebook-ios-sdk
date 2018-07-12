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

/**
 A base interface for content to be shared.
 */
public protocol ContentProtocol {
  associatedtype Result: ContentSharingResultProtocol

  /**
   URL for the content being shared.

   This URL will be checked for all link meta tags for linking in platform specific ways.
   See documentation for [App Links](https://developers.facebook.com/docs/applinks/)
   */
  var url: URL? { get }

  /// Hashtag for the content being shared.
  var hashtag: Hashtag? { get }

  /**
   List of IDs for taggable people to tag with this content.

   See documentation for
   [Taggable Friends](https://developers.facebook.com/docs/graph-api/reference/user/taggable_friends)
   */
  var taggedPeopleIds: [String]? { get }

  /// The ID for a place to tag with this content.
  var placeId: String? { get }

  /// A value to be added to the referrer URL when a person follows a link from this shared content on feed.
  var referer: String? { get }
}
