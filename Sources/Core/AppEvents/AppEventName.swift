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
 Represents a name of the Facebook Analytics application event.
 Could either be one of built-in names or a custom `String`.

 - seealso: AppEvent
 - seealso: AppEventLoggable
 */
public enum AppEventName {

  // MARK: General

  /// Name of the event that indicates that the user has completed a registration.
  case CompletedRegistration
  /// Name of the event that indicates that the user has completed a tutorial.
  case CompletedTutorial
  /// Name of the event that indicates that the user has viewed a content.
  case ViewedContent
  /// Name of the event that indicates that the user has performed search within the application.
  case Searched
  /// Name of the event that indicates that the user has has rated an item in the app.
  case Rated

  // MARK: Commerce

  /// Name of the event that indicates that the user has purchased something in the application.
  case Purchased
  /// Name of the event that indicates that the user has added an item to the cart.
  case AddedToCart
  /// Name of the event that indicates that the user has added an item to the wishlist.
  case AddedToWishlist
  /// Name of the event that indicates that the user has added payment information.
  case AddedPaymentInfo
  /// Name of the event that indicates that the user has initiated a checkout.
  case InitiatedCheckout

  // MARK: Gaming

  /// Name of the event that indicates that the user has achieved a level.
  case AchievedLevel
  /// Name of the event that indicates that the user has unlocked an achievement.
  case UnlockedAchievement
  /// Name of the event that indicates that the user has spent in-app credits.
  case SpentCredits

  // MARK: Custom

  /// Custom name of the event that is represented by a string.
  case Custom(String)

  /**
   Create an `AppEventName` from `String`.

   - parameter string: String to create an app event name from.
   */
  public init(_ string: String) {
    self = .Custom(string)
  }
}

extension AppEventName: RawRepresentable {
  /**
   Create an `AppEventName` from `String`.

   - parameter rawValue: String to create an app event name from.
   */
  public init?(rawValue: String) {
    self = .Custom(rawValue)
  }

  /// The corresponding `String` value.
  public var rawValue: String {
    switch self {
    case .CompletedRegistration: return FBSDKAppEventNameCompletedRegistration
    case .CompletedTutorial: return FBSDKAppEventNameCompletedTutorial
    case .ViewedContent: return FBSDKAppEventNameViewedContent
    case .Searched: return FBSDKAppEventNameSearched
    case .Rated: return FBSDKAppEventNameRated

    case .Purchased: return "fb_mobile_purchase" // Hard-coded as a string, since it's internal API of FBSDKCoreKit.
    case .AddedToCart: return FBSDKAppEventNameAddedToCart
    case .AddedToWishlist: return FBSDKAppEventNameAddedToWishlist
    case .AddedPaymentInfo: return FBSDKAppEventNameAddedPaymentInfo
    case .InitiatedCheckout: return FBSDKAppEventNameInitiatedCheckout

    case .AchievedLevel: return FBSDKAppEventNameAchievedLevel
    case .UnlockedAchievement: return FBSDKAppEventNameUnlockedAchievement
    case .SpentCredits: return FBSDKAppEventNameSpentCredits

    case .Custom(let string): return string
    }
  }
}

extension AppEventName: StringLiteralConvertible {
  /**
   Create an `AppEventName` from a string literal.

   - parameter value: The string literal to create from.
   */
  public init(stringLiteral value: StringLiteralType) {
    self = .Custom(value)
  }

  /**
   Create an `AppEventName` from a unicode scalar literal.

   - parameter value: The string literal to create from.
   */
  public init(unicodeScalarLiteral value: String) {
    self.init(stringLiteral: value)
  }

  /**
   Create an `AppEventName` from an extended grapheme cluster.

   - parameter value: The string literal to create from.
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(stringLiteral: value)
  }
}

extension AppEventName: Hashable {
  /// The hash value.
  public var hashValue: Int {
    return self.rawValue.hashValue
  }
}

extension AppEventName: CustomStringConvertible {
  /// Textual representation of an app event name.
  public var description: String {
    return rawValue
  }
}

/**
 Compare two `AppEventName`s for equality.

 - parameter lhs: The first app event name to compare.
 - parameter rhs: The second app event name to compare.

 - returns: Whether or not the app event names are equal.
 */
public func == (lhs: AppEventName, rhs: AppEventName) -> Bool {
  return lhs.rawValue == rhs.rawValue
}
