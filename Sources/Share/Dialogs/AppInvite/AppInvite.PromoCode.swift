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

extension AppInvite {
  /**
   A promo code for an App Invite promotion. This can be between 0 and 10 characters long, and can contain alphanumeric
   and spaces only.

   If you attempt to create a Promo Code with an invalid string literal, you will receive a runtime warning, and your
   code will be truncated.
   */
  public struct PromoCode: Equatable, Hashable {
    internal let rawValue: String

    /**
     Attempt to create a promo code from a string.

     - parameter string: The string to initialize from.
     */
    public init?(string: String) {
      let truncated = PromoCode.truncateString(string)
      if string != truncated {
        return nil
      }

      rawValue = string
    }

    /// The hash of this promo code.
    public var hashValue: Int {
      return rawValue.hashValue
    }
  }
}

extension AppInvite.PromoCode {
  private static func truncateString(string: String) -> String {
    let validCharacters = NSCharacterSet.alphanumericCharacterSet()
    let cleaned = string.unicodeScalars.filter {
      validCharacters.characterIsMember(UInt16($0.value))
    }

    let range = 0 ..< min(10, cleaned.count)
    let characters = cleaned[range].map(Character.init)

    return String(characters)
  }
}

extension AppInvite.PromoCode: StringLiteralConvertible {
  /**
   Create a PromoCode from a string literal.

   - parameter value: The string literal to intiialize from.
   */
  public init(stringLiteral value: String) {
    let truncated = AppInvite.PromoCode.truncateString(value)
    if truncated != value {
      print("Warning: Attempted to create a PromoCode from \"\(value)\" which contained invalid characters, or was too long.")
    }

    rawValue = truncated
  }

  /**
   Create a PromoCode from a unicode scalar literal.

   - parameter value: The string literal to intiialize from.
   */
  public init(unicodeScalarLiteral value: String) {
    self.init(stringLiteral: value)
  }

  /**
   Create a PromoCode from an extended grapheme cluster literal.

   - parameter value: The string literal to initialize from.
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(stringLiteral: value)
  }
}

/**
 Compare two `PromoCode`s for equality.

 - parameter lhs: The first promo code to compare.
 - parameter rhs: The second promo code to compare.

 - returns: Whether or not the promo codes are equal.
 */
public func == (lhs: AppInvite.PromoCode, rhs: AppInvite.PromoCode) -> Bool {
  return lhs.rawValue == rhs.rawValue
}
