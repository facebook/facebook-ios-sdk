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

//--------------------------------------
// MARK: - General
//--------------------------------------

public extension AppEvent {
  /**
   Create an event that indicates that the user has completed registration.

   - parameter registrationMethod: Optional registration method used.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func completedRegistration(registrationMethod: String? = nil,
                                    valueToSum: Double? = nil,
                                    extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    registrationMethod.onSome { parameters[.registrationMethod] = $0 }
    return AppEvent(name: .completedRegistration, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicates that the user has completed tutorial.

   - parameter successful: Optional boolean value that indicates whether operation was succesful.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func completedTutorial(successful: Bool? = nil,
                                valueToSum: Double? = nil,
                                extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    successful.onSome { parameters[.successful] = $0 ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo }
    return AppEvent(name: .completedTutorial, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicates that the user viewed specific content.

   - parameter contentType: Optional content type.
   - parameter contentId: Optional content identifier.
   - parameter currency: Optional string representation of currency.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func viewedContent(contentType: String? = nil,
                            contentId: String? = nil,
                            currency: String? = nil,
                            valueToSum: Double? = nil,
                            extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    currency.onSome { parameters[.currency] = $0 }
    return AppEvent(name: .viewedContent, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that the user has performed a search within the app.

   - parameter contentId: Optional content identifer.
   - parameter searchedString: Optional searched string.
   - parameter successful: Optional boolean value that indicatest whether the operation was succesful.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func searched(contentId: String? = nil,
                       searchedString: String? = nil,
                       successful: Bool? = nil,
                       valueToSum: Double? = nil,
                       extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentId.onSome { parameters[.contentId] = $0 }
    searchedString.onSome { parameters[.searchedString] = $0 }
    successful.onSome { parameters[.successful] = $0 ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo }
    return AppEvent(name: .searched, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest the user has rated an item in the app.

   - parameter contentType: Optional type of the content.
   - parameter contentId: Optional content identifier.
   - parameter maxRatingValue: Optional max rating value.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func rated<T: UnsignedInteger>(contentType: String? = nil,
                                        contentId: String? = nil,
                                        maxRatingValue: T? = nil,
                                        valueToSum: Double? = nil,
                                        extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    maxRatingValue.onSome { parameters[.maxRatingValue] = NSNumber(value: UInt64($0)) }
    return AppEvent(name: .rated, parameters: parameters, valueToSum: valueToSum)
  }
}

//--------------------------------------
// MARK: - Commerce
//--------------------------------------

public extension AppEvent {

  /**
   Create an app event that a user has purchased something in the application.

   - parameter amount: An amount of purchase.
   - parameter currency: Optional string representation of currency.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func purchased(amount: Double,
                        currency: String? = nil,
                        extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    currency.onSome { parameters[.currency] = $0 }
    return AppEvent(name: .purchased, parameters: parameters, valueToSum: amount)
  }

  /**
   Create an app event that indicatest that user has added an item to the cart.

   - parameter contentType: Optional content type.
   - parameter contentId: Optional content identifier.
   - parameter currency: Optional string representation of currency.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func addedToCart(contentType: String? = nil,
                          contentId: String? = nil,
                          currency: String? = nil,
                          valueToSum: Double? = nil,
                          extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    currency.onSome { parameters[.currency] = $0 }
    return AppEvent(name: .addedToCart, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an app event that indicates that user added an item to the wishlist.

   - parameter contentType: Optional content type.
   - parameter contentId: Optional content identifier.
   - parameter currency: Optional string representation of currency.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func addedToWishlist(contentType: String? = nil,
                              contentId: String? = nil,
                              currency: String? = nil,
                              valueToSum: Double? = nil,
                              extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    currency.onSome { parameters[.currency] = $0 }
    return AppEvent(name: .addedToWishlist, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user added payment information.

   - parameter successful: Optional boolean value that indicates whether operation was succesful.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func addedPaymentInfo(successful: Bool? = nil,
                               valueToSum: Double? = nil,
                               extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    successful.onSome { parameters[.successful] = $0 ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo }
    return AppEvent(name: .addedPaymentInfo, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user has initiated a checkout.

   - parameter contentType: Optional content type.
   - parameter contentId: Optional content identifier.
   - parameter itemCount: Optional count of items.
   - parameter paymentInfoAvailable: Optional boolean value that indicatest whether payment info is available.
   - parameter currency: Optional string representation of currency.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func initiatedCheckout<T: UnsignedInteger>(contentType: String? = nil,
                                                    contentId: String? = nil,
                                                    itemCount: T? = nil,
                                                    paymentInfoAvailable: Bool? = nil,
                                                    currency: String? = nil,
                                                    valueToSum: Double? = nil,
                                                    extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    itemCount.onSome { parameters[.itemCount] = NSNumber(value: UInt64($0)) }
    paymentInfoAvailable.onSome {
      parameters[.paymentInfoAvailable] = $0 ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo
    }
    currency.onSome { parameters[.currency] = $0 }
    return AppEvent(name: .initiatedCheckout, parameters: parameters, valueToSum: valueToSum)
  }
}

//--------------------------------------
// MARK: - Gaming
//--------------------------------------

public extension AppEvent {

  /**
   Create an app event that indicates that a user has achieved a level in the application.

   - parameter level: Optional level achieved. Can be either a `String` or `NSNumber`.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func achievedLevel(level: AppEventParameterValueType? = nil,
                            valueToSum: Double? = nil,
                            extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    level.onSome { parameters[.level] = $0 }
    return AppEvent(name: .achievedLevel, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an app event that indicatest that a user has unlocked an achievement.

   - parameter description: Optional achievement description.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func unlockedAchievement(description: String? = nil,
                                  valueToSum: Double? = nil,
                                  extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    description.onSome { parameters[.description] = $0 }
    return AppEvent(name: .unlockedAchievement, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user spent in-app credits.

   - parameter contentType: Optional content type.
   - parameter contentId: Optional content identifier.
   - parameter valueToSum: Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  static func spentCredits(contentType: String? = nil,
                           contentId: String? = nil,
                           valueToSum: Double? = nil,
                           extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome { parameters[.contentType] = $0 }
    contentId.onSome { parameters[.contentId] = $0 }
    return AppEvent(name: .spentCredits, parameters: parameters, valueToSum: valueToSum)
  }
}
