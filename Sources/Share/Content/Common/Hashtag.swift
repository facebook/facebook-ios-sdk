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

/**
 Represents a valid hashtag.
 */
public struct Hashtag: Hashable {
  /// The hashtag string.
  public let stringValue: String

  /**
   Attempt to create a hashtag for a given string.

   - parameter string: The string to create from.
   If this is not a valid hashtag (matching the regular expression `#\w+`), the initializer returns `nil`.
   */
  public init?(_ string: String) {
    guard let sdkHashtag = FBSDKHashtag(string: string) else { return nil }
    self.init(sdkHashtag: sdkHashtag)
  }

  internal init?(sdkHashtag: FBSDKHashtag) {
    if !sdkHashtag.isValid {
      return nil
    }
    self.stringValue = sdkHashtag.stringRepresentation
  }

  internal var sdkHashtagRepresentation: FBSDKHashtag {
    return FBSDKHashtag(string: stringValue)
  }

  // MARK: Hashable

  /// Calculates the hash value of this Hashtag (yo dawg).
  public var hashValue: Int {
    return stringValue.hashValue
  }

  /**
   Check if two hashtags are equal.

   - parameter lhs: The first hashtag to compare.
   - parameter rhs: The second hashtag to compare.

   - returns: `true` if the hashtags are equal, `false` otherwise.
   */
  public static func == (lhs: Hashtag, rhs: Hashtag) -> Bool {
    return lhs.stringValue == rhs.stringValue
  }

}
