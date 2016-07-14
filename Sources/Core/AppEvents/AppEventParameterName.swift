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

import FBSDKCoreKit.FBSDKAppEvents

/**
 Represents a parameter name of the Facebook Analytics application event.
 */
public enum AppEventParameterName {
  /// Identifier for the specific piece of content.
  case ContentId
  /// Type of the content, e.g. "music"/"photo"/"video".
  case ContentType
  /// Currency. E.g. "USD"/"EUR"/"GBP". See ISO-4217 for specific values.
  case Currency
  /// Appropriate description for the event.
  case Description
  /// Current level or level achieved.
  case Level
  /// Maximum rating available. E.g. "5"/"10".
  case MaxRatingValue
  /// Count of items being proccessed.
  case ItemCount
  /// Boolean value indicating whether payment information is available.
  case PaymentInfoAvailable
  /// Registration method used. E.g. "Facebook"/"email"/"sms".
  case RegistrationMethod
  /// String provided by the user for a search operation.
  case SearchedString
  /// Boolean value indicating wehtehr an activity being logged was succesful.
  case Successful
  /// Custom name of the parameter that is represented by a string.
  case Custom(String)

  /**
   Create an `AppEventParameterName` from `String`.

   - parameter string: String to create an app event name from.
   */
  public init(_ string: String) {
    self = .Custom(string)
  }
}

extension AppEventParameterName: RawRepresentable {
  /**
   Create an `AppEventParameterName` from `String`.

   - parameter rawValue: String to create an app event name from.
   */
  public init?(rawValue: String) {
    self = .Custom(rawValue)
  }

  /// The corresponding `String` value.
  public var rawValue: String {
    switch self {
    case .ContentId: return FBSDKAppEventParameterNameContentID
    case .ContentType: return FBSDKAppEventParameterNameContentType
    case .Currency: return FBSDKAppEventParameterNameCurrency
    case .Description: return FBSDKAppEventParameterNameDescription
    case .Level: return FBSDKAppEventNameAchievedLevel
    case .MaxRatingValue: return FBSDKAppEventParameterNameMaxRatingValue
    case .ItemCount: return FBSDKAppEventParameterNameNumItems
    case .PaymentInfoAvailable: return FBSDKAppEventParameterNamePaymentInfoAvailable
    case .RegistrationMethod: return FBSDKAppEventParameterNameRegistrationMethod
    case .SearchedString: return FBSDKAppEventParameterNameSearchString
    case .Successful: return FBSDKAppEventParameterNameSuccess
    case .Custom(let string): return string
    }
  }
}

extension AppEventParameterName: StringLiteralConvertible {
  /**
   Create an `AppEventParameterName` from a string literal.

   - parameter value: The string literal to create from.
   */
  public init(stringLiteral value: StringLiteralType) {
    self = .Custom(value)
  }

  /**
   Create an `AppEventParameterName` from a unicode scalar literal.

   - parameter value: The string literal to create from.
   */
  public init(unicodeScalarLiteral value: String) {
    self.init(stringLiteral: value)
  }

  /**
   Create an `AppEventParameterName` from an extended grapheme cluster.

   - parameter value: The string literal to create from.
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(stringLiteral: value)
  }
}

extension AppEventParameterName: Hashable {
  /// The hash value.
  public var hashValue: Int {
    return self.rawValue.hashValue
  }
}

extension AppEventParameterName: CustomStringConvertible {
  /// Textual representation of an app event parameter name.
  public var description: String {
    return rawValue
  }
}

/**
 Compare two `AppEventParameterName`s for equality.

 - parameter lhs: The first parameter name to compare.
 - parameter rhs: The second parameter name to compare.

 - returns: Whether or not the parameter names are equal.
 */
public func == (lhs: AppEventParameterName, rhs: AppEventParameterName) -> Bool {
  return lhs.rawValue == rhs.rawValue
}
