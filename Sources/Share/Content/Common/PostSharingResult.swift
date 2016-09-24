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
 Represents the results of a successful Facebook post share.
 */
public struct PostSharingResult: ContentSharingResultProtocol {
  fileprivate let dictionary: [String : String]

  /**
   Initialize this result from the contents of a dictionary

   - parameter dictionary: The dictionary to initialize from
   */
  public init(dictionary: [String : String]) {
    self.dictionary = dictionary
  }

  /// The post ID of the shared content
  public var postId: String? {
    get {
      return dictionary[ShareResultKeys.PostId.rawValue]
    }
  }

  /**
   Get the value of a given key from this result.

   - parameter key: A key to search for.

   - returns: The value associated with that key.
   */
  public subscript(key: String) -> String? {
    return dictionary[key]
  }
}
