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

/**
 The common interface for components that initiate sharing.
 */
public protocol ContentSharingProtocol {
  associatedtype Content: ContentProtocol

  /// The content that is being shared.
  var content: Content { get }

  /// The completion handler to call when sharing is complete.
  var completion: ((ContentSharerResult<Content>) -> Void)? { get set }

  /**
   A Boolean value that indicates whether the receiver should fail if it finds an error with the share content.

   If `false`, the sharer will still be displayed without the data that was mis-configured.
   For example, an invalid `placeId` specified on the `content` would produce a data error.
   */
  var failsOnInvalidData: Bool { get }

  /**
   Validates the content on the receiver.
   */
  func validate() throws
}

/**
 The results of an attempted operation by a `ContentSharer`.
 */
public enum ContentSharerResult<Content: ContentProtocol> {
  /// The operation was successful.
  case Success(Content.Result)

  /// The operation failed.
  case Failed(ErrorType)

  /// The operation was cancelled by the user.
  case Cancelled
}
