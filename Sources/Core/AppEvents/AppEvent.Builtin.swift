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

extension AppEvent {
  /**
   Create an event that indicates that the user has completed registration.

   - parameter registrationMethod: Optional registration method used.
   - parameter valueToSum:         Optional value to sum.
   - parameter extraParameters:    Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func CompletedRegistration(registrationMethod registrationMethod: String? = nil,
                                                              valueToSum: Double? = nil,
                                                              extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    registrationMethod.onSome({ parameters[.RegistrationMethod] = $0 })
    return AppEvent(name: .CompletedRegistration, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicates that the user has completed tutorial.

   - parameter successful:      Optional boolean value that indicates whether operation was succesful.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func CompletedTutorial(successful successful: BooleanType? = nil,
                                                  valueToSum: Double? = nil,
                                                  extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    successful.onSome({ parameters[.Successful] = $0.boolValue ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo })
    return AppEvent(name: .CompletedTutorial, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicates that the user viewed specific content.

   - parameter contentType:     Optional content type.
   - parameter contentId:       Optional content identifier.
   - parameter currency:        Optional string representation of currency.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func ViewedContent(contentType contentType: String? = nil,
                                               contentId: String? = nil,
                                               currency: String? = nil,
                                               valueToSum: Double? = nil,
                                               extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    currency.onSome({ parameters[.Currency] = $0 })
    return AppEvent(name: .ViewedContent, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that the user has performed a search within the app.

   - parameter contentId:       Optional content identifer.
   - parameter searchedString:  Optional searched string.
   - parameter successful:      Optional boolean value that indicatest whether the operation was succesful.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func Searched(contentId contentId: String? = nil,
                                        searchedString: String? = nil,
                                        successful: BooleanType? = nil,
                                        valueToSum: Double? = nil,
                                        extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentId.onSome({ parameters[.ContentId] = $0 })
    searchedString.onSome({ parameters[.SearchedString] = $0 })
    successful.onSome({ parameters[.Successful] = $0.boolValue ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo })
    return AppEvent(name: .Searched, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest the user has rated an item in the app.

   - parameter contentType:     Optional type of the content.
   - parameter contentId:       Optional content identifier.
   - parameter maxRatingValue:  Optional max rating value.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func Rated<T: UnsignedIntegerType>(
    contentType contentType: String? = nil,
                contentId: String? = nil,
                maxRatingValue: T? = nil,
                valueToSum: Double? = nil,
                extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    maxRatingValue.onSome({ parameters[.MaxRatingValue] = NSNumber(unsignedLongLong: $0.toUIntMax()) })
    return AppEvent(name: .Rated, parameters: parameters, valueToSum: valueToSum)
  }
}

//--------------------------------------
// MARK: - Commerce
//--------------------------------------

extension AppEvent {

  /**
   Create an app event that a user has purchased something in the application.

   - parameter amount:          An amount of purchase.
   - parameter currency:        Optional string representation of currency.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func Purchased(amount amount: Double,
                                      currency: String? = nil,
                                      extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    currency.onSome({ parameters[.Currency] = $0 })
    return AppEvent(name: .Purchased, parameters: parameters, valueToSum: amount)
  }

  /**
   Create an app event that indicatest that user has added an item to the cart.

   - parameter contentType:     Optional content type.
   - parameter contentId:       Optional content identifier.
   - parameter currency:        Optional string representation of currency.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func AddedToCart(contentType contentType: String? = nil,
                                             contentId: String? = nil,
                                             currency: String? = nil,
                                             valueToSum: Double? = nil,
                                             extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    currency.onSome({ parameters[.Currency] = $0 })
    return AppEvent(name: .AddedToCart, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an app event that indicates that user added an item to the wishlist.

   - parameter contentType:     Optional content type.
   - parameter contentId:       Optional content identifier.
   - parameter currency:        Optional string representation of currency.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func AddedToWishlist(contentType contentType: String? = nil,
                                                 contentId: String? = nil,
                                                 currency: String? = nil,
                                                 valueToSum: Double? = nil,
                                                 extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    currency.onSome({ parameters[.Currency] = $0 })
    return AppEvent(name: .AddedToWishlist, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user added payment information.

   - parameter successful:      Optional boolean value that indicates whether operation was succesful.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func AddedPaymentInfo(successful successful: BooleanType? = nil,
                                                 valueToSum: Double? = nil,
                                                 extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    successful.onSome({ parameters[.Successful] = $0.boolValue ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo })
    return AppEvent(name: .AddedPaymentInfo, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user has initiated a checkout.

   - parameter contentType:          Optional content type.
   - parameter contentId:            Optional content identifier.
   - parameter itemCount:            Optional count of items.
   - parameter paymentInfoAvailable: Optional boolean value that indicatest whether payment info is available.
   - parameter currency:             Optional string representation of currency.
   - parameter valueToSum:           Optional value to sum.
   - parameter extraParameters:      Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func InitiatedCheckout<T: UnsignedIntegerType>(
    contentType contentType: String? = nil,
                contentId: String? = nil,
                itemCount: T? = nil,
                paymentInfoAvailable: BooleanType? = nil,
                currency: String? = nil,
                valueToSum: Double? = nil,
                extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    itemCount.onSome({ parameters[.ItemCount] = NSNumber(unsignedLongLong: $0.toUIntMax()) })
    paymentInfoAvailable.onSome({
      parameters[.PaymentInfoAvailable] = $0.boolValue ? FBSDKAppEventParameterValueYes : FBSDKAppEventParameterValueNo
    })
    currency.onSome({ parameters[.Currency] = $0 })
    return AppEvent(name: .InitiatedCheckout, parameters: parameters, valueToSum: valueToSum)
  }
}

//--------------------------------------
// MARK: - Gaming
//--------------------------------------

extension AppEvent {

  /**
   Create an app event that indicates that a user has achieved a level in the application.

   - parameter level:           Optional level achieved. Can be either a `String` or `NSNumber`.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func AchievedLevel(level level: AppEventParameterValueType? = nil,
                                         valueToSum: Double? = nil,
                                         extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    level.onSome({ parameters[.Level] = $0 })
    return AppEvent(name: .AchievedLevel, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an app event that indicatest that a user has unlocked an achievement.

   - parameter description:     Optional achievement description.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func UnlockedAchievement(description description: String? = nil,
                                                     valueToSum: Double? = nil,
                                                     extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    description.onSome({ parameters[.Description] = $0 })
    return AppEvent(name: .UnlockedAchievement, parameters: parameters, valueToSum: valueToSum)
  }

  /**
   Create an event that indicatest that a user spent in-app credits.

   - parameter contentType:     Optional content type.
   - parameter contentId:       Optional content identifier.
   - parameter valueToSum:      Optional value to sum.
   - parameter extraParameters: Optional dictionary of extra parameters.

   - returns: An app event that can be logged via `AppEventsLogger`.
   */
  public static func SpentCredits(
    contentType contentType: String? = nil,
                contentId: String? = nil,
                valueToSum: Double? = nil,
                extraParameters: ParametersDictionary = [:]) -> AppEvent {
    var parameters = extraParameters
    contentType.onSome({ parameters[.ContentType] = $0 })
    contentId.onSome({ parameters[.ContentId] = $0 })
    return AppEvent(name: .SpentCredits, parameters: parameters, valueToSum: valueToSum)
  }
}
