/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

// MARK: App parameters

enum AppEventName: String {
  case unlockedAchievement = "fb_mobile_achievement_unlocked"
  case activatedApp = "fb_mobile_activate_app"
  case addedPaymentInfo = "fb_mobile_add_payment_info"
  case addedToCart = "fb_mobile_add_to_cart"
  case addedToWishlist = "fb_mobile_add_to_wishlist"
  case completedRegistration = "fb_mobile_complete_registration"
  case viewedContent = "fb_mobile_content_view"
  case initiatedCheckout = "fb_mobile_initiated_checkout"
  case achievedLevel = "fb_mobile_level_achieved"
  case purchased = "fb_mobile_purchase"
  case rated = "fb_mobile_rate"
  case searched = "fb_mobile_search"
  case spentCredits = "fb_mobile_spent_credits"
  case completedTutorial = "fb_mobile_tutorial_completion"
}

enum CustomEventField: String {
  case eventTime = "_logTime"
  case eventName = "_eventName"
  case valueToSum = "_valueToSum"
  case contentIds = "content_ids"
  case contents = "fb_content_id"
  case contentType = "fb_content_type"
  case description = "fb_description"
  case level = "fb_level"
  case maxRatingValue = "fb_max_rating_value"
  case numItems = "fb_num_items"
  case paymentInfoAvailable = "fb_payment_info_available"
  case registrationMethod = "fb_registration_method"
  case searchString = "fb_search_string"
  case success = "fb_success"
  case orderId = "fb_order_id"
  case adType = "ad_type"
  case currency = "fb_currency"
}

enum AppEventType: String {
  case mobileAppInstall
  case custom
  case other

  init(rawValue: String) {
    switch rawValue {
    case "MOBILE_APP_INSTALL": self = .mobileAppInstall
    case "CUSTOM_APP_EVENTS": self = .custom
    default: self = .other
    }
  }
}

enum AppEventUserAndAppDataField: String {
  // user data fields
  case anonId = "anon_id"
  case appUserId = "app_user_id"
  case advertiserId = "advertiser_id"
  case pageId = "page_id"
  case pageScopedUserId = "page_scoped_user_id"
  case userData = "ud"

  // app data fields
  case advTE = "advertiser_tracking_enabled"
  case appTE = "application_tracking_enabled"
  case considerViews = "consider_views"
  case deviceToken = "device_token"
  case extinfo
  case includeDwellData = "include_dwell_data"
  case includeVideoData = "include_video_data"
  case installReferrer = "install_referrer"
  case installerPackage = "installer_package"
  case receiptData = "receipt_data"
  case urlSchemes = "url_schemes"
}

// MARK: ConversionsAPI parameters

enum ConversionsAPISection: String {
  case userData = "user_data"
  case appData = "app_data"
  case customData = "custom_data"
  case customEvents = "custom_events"
}

enum ConversionsAPICustomEventField: String {
  case valueToSum = "value"
  case eventTime = "event_time"
  case eventName = "event_name"
  case contentIds = "content_ids"
  case contents
  case contentType = "content_type"
  case description
  case level
  case maxRatingValue = "max_rating_value"
  case numItems = "num_items"
  case paymentInfoAvailable = "payment_info_available"
  case registrationMethod = "registration_method"
  case searchString = "search_string"
  case success
  case orderId = "order_id"
  case adType = "ad_type"
  case currency
}

enum ConversionsAPIUserAndAppDataField: String {
  // user data fields
  case anonId = "anon_id"
  case fbLoginId = "fb_login_id"
  case madid
  case pageId = "page_id"
  case pageScopedUserId = "page_scoped_user_id"
  case userData = "ud"

  // app data fields
  case advTE = "advertiser_tracking_enabled"
  case appTE = "application_tracking_enabled"
  case considerViews = "consider_views"
  case deviceToken = "device_token"
  case extinfo
  case includeDwellData = "include_dwell_data"
  case includeVideoData = "include_video_data"
  case installReferrer = "install_referrer"
  case installerPackage = "installer_package"
  case receiptData = "receipt_data"
  case urlSchemes = "url_schemes"
}

enum ConversionsAPIEventName: String {
  case achievementUnlocked = "AchievementUnlocked"
  case activateApp = "ActivateApp"
  case addPaymentInfo = "AddPaymentInfo"
  case addToCart = "AddToCart"
  case addToWishlist = "AddToWishlist"
  case completeRegistration = "CompleteRegistration"
  case viewContent = "ViewContent"
  case initiateCheckout = "InitiateCheckout"
  case levelAchieved = "LevelAchieved"
  case purchase = "Purchase"
  case rate = "Rate"
  case search = "Search"
  case spentCredits = "SpentCredits"
  case tutorialCompletion = "TutorialCompletion"
}

enum OtherEventConstants: String {
  case event
  case actionSource = "action_source"
  case app
  case mobileAppInstall = "MobileAppInstall"
  case installEventTime = "install_timestamp"
}

// MARK: App Events to Conversions API Transformer dictionaries

enum AppEventsConversionsAPITransformer {

  struct SectionFieldMapping {
    let section: ConversionsAPISection
    let field: ConversionsAPIUserAndAppDataField?
  }

  static let topLevelTransformations: [AppEventUserAndAppDataField: SectionFieldMapping] = [
    // user_data mapping
    .anonId: .init(section: .userData, field: .anonId),
    .appUserId: .init(section: .userData, field: .fbLoginId),
    .advertiserId: .init(section: .userData, field: .madid),
    .pageId: .init(section: .userData, field: .pageId),
    .pageScopedUserId: .init(section: .userData, field: .pageScopedUserId),

    // app_data mapping
    .advTE: .init(section: .appData, field: .advTE),
    .appTE: .init(section: .appData, field: .appTE),
    .considerViews: .init(section: .appData, field: .considerViews),
    .deviceToken: .init(section: .appData, field: .deviceToken),
    .extinfo: .init(section: .appData, field: .extinfo),
    .includeDwellData: .init(section: .appData, field: .includeDwellData),
    .includeVideoData: .init(section: .appData, field: .includeVideoData),
    .installReferrer: .init(section: .appData, field: .installReferrer),
    .installerPackage: .init(section: .appData, field: .installerPackage),
    .receiptData: .init(section: .appData, field: .receiptData),
    .urlSchemes: .init(section: .appData, field: .urlSchemes),
    .userData: .init(section: .userData, field: nil),
  ]

  struct SectionCustomEventFieldMapping {
    let section: ConversionsAPISection?
    let field: ConversionsAPICustomEventField
  }

  static let customEventTransformations: [CustomEventField: SectionCustomEventFieldMapping] = [
    // custom_events mapping
    .eventTime: .init(section: nil, field: .eventTime),
    .eventName: .init(section: nil, field: .eventName),
    .valueToSum: .init(section: .customData, field: .valueToSum),
    .contentIds: .init(section: .customData, field: .contentIds), // string to array conversion required
    .contents: .init(section: .customData, field: .contents), // string to array conversion required, contents has an extra field: price
    .contentType: .init(section: .customData, field: .contentType),
    .currency: .init(section: .customData, field: .currency),
    .description: .init(section: .customData, field: .description),
    .level: .init(section: .customData, field: .level),
    .maxRatingValue: .init(section: .customData, field: .maxRatingValue),
    .numItems: .init(section: .customData, field: .numItems),
    .paymentInfoAvailable: .init(section: .customData, field: .paymentInfoAvailable),
    .registrationMethod: .init(section: .customData, field: .registrationMethod),
    .searchString: .init(section: .customData, field: .searchString),
    .success: .init(section: .customData, field: .success),
    .orderId: .init(section: .customData, field: .orderId),
    .adType: .init(section: .customData, field: .adType),
  ]

  static let standardEventTransformations: [AppEventName: ConversionsAPIEventName] = [
    .unlockedAchievement: .achievementUnlocked,
    .activatedApp: .activateApp,
    .addedPaymentInfo: .addPaymentInfo,
    .addedToCart: .addToCart,
    .addedToWishlist: .addToWishlist,
    .completedRegistration: .completeRegistration,
    .viewedContent: .viewContent,
    .initiatedCheckout: .initiateCheckout,
    .achievedLevel: .levelAchieved,
    .purchased: .purchase,
    .rated: .rate,
    .searched: .search,
    .spentCredits: .spentCredits,
    .completedTutorial: .tutorialCompletion,
  ]

  enum DataProcessingParameterName: String, CaseIterable {
    case options = "data_processing_options"
    case country = "data_processing_options_country"
    case state = "data_processing_options_state"
  }

  enum ValueTransformationType: String, CaseIterable {
    case array
    case bool
    case int

    init?(field: String) {
      switch field {
      case AppEventUserAndAppDataField.extinfo.rawValue: self = .array
      case AppEventUserAndAppDataField.urlSchemes.rawValue: self = .array
      case CustomEventField.contentIds.rawValue: self = .array
      case CustomEventField.contents.rawValue: self = .array
      case DataProcessingParameterName.options.rawValue: self = .array
      case AppEventUserAndAppDataField.advTE.rawValue: self = .bool
      case AppEventUserAndAppDataField.appTE.rawValue: self = .bool
      case CustomEventField.eventTime.rawValue: self = .int
      default: return nil
      }
    }
  }

  static func transformValue(field: String, value: Any) -> Any? {
    guard let type = ValueTransformationType(field: field),
          let param = value as? String,
          let data = param.data(using: .utf8)
    else {
      return value
    }

    switch type {
    case .array:
      guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any]
      else {
        return value
      }
      return array
    case .bool:
      guard let coercedInteger = Int(param) else {
        return value
      }
      return coercedInteger != 0
    case .int:
      guard let int = value as? Int ?? Int(value as? String ?? "") else {
        return nil
      }
      return int
    }
  }

  // MARK: split app events parameters into user, app data and custom events

  static func splitAppEventParameters(
    from parameters: [String: Any],
    userData: inout [String: Any],
    appData: inout [String: Any],
    restOfData: inout [String: Any],
    customEvents: inout [[String: Any]]
  ) -> AppEventType? {

    guard let eventTypeRaw = parameters[OtherEventConstants.event.rawValue] as? String,
          let eventType = AppEventType(rawValue: eventTypeRaw) as AppEventType?,
          eventType != .other else {
      return .other
    }

    parameters.forEach { key, value in
      if let field = AppEventUserAndAppDataField(rawValue: key) {
        transformAndUpdateAppAndUserData(userData: &userData, appData: &appData, field: field, value: value)
      } else if let rawEvents = value as? String,
                key == ConversionsAPISection.customEvents.rawValue,
                eventType == .custom,
                let events = transformEvents(from: rawEvents) {
        customEvents = events
      } else if DataProcessingParameterName(rawValue: key) != nil {
        restOfData[key] = transformValue(field: key, value: value)
      }
    }
    return eventType
  }

  // MARK: user and app data transformations

  static func transformAndUpdateAppData(
    _ appData: inout [String: Any],
    field: AppEventUserAndAppDataField,
    value: Any
  ) {
    guard let key = topLevelTransformations[field]?.field?.rawValue else {
      return
    }
    appData[key] = transformValue(field: field.rawValue, value: value)
  }

  static func transformAndUpdateUserData(
    _ userData: inout [String: Any],
    field: AppEventUserAndAppDataField,
    value: Any
  ) {
    if field == .userData {
      guard let udParam = value as? String,
            let data = udParam.data(using: .utf8),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      else {
        return
      }
      userData.merge(dictionary) { $1 }
    } else {
      guard let key = topLevelTransformations[field]?.field?.rawValue else {
        return
      }
      userData[key] = transformValue(field: field.rawValue, value: value)
    }
  }

  static func transformAndUpdateAppAndUserData(
    userData: inout [String: Any],
    appData: inout [String: Any],
    field: AppEventUserAndAppDataField,
    value: Any
  ) {
    guard let section = topLevelTransformations[field]?.section else {
      return
    }
    switch section {
    case .appData:
      transformAndUpdateAppData(&appData, field: field, value: value)
    case .userData:
      transformAndUpdateUserData(&userData, field: field, value: value)
    default:
      return
    }
  }

  // MARK: events section transformations

  static func transformEventName(from rawEventName: String) -> String {
    guard let eventName = AppEventName(rawValue: rawEventName) else {
      return rawEventName
    }
    return standardEventTransformations[eventName]?.rawValue ?? ""
  }

  static func transformEvents(
    from appEvents: String
  ) -> [[String: Any]]? {
    guard let data = appEvents.data(using: .utf8),
          let events = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
          !appEvents.isEmpty
    else {
      return nil
    }

    var transformedEvents = [[String: Any]]()
    events.forEach { event in
      var customData = [String: Any]()
      var transformedEvent = [String: Any]()
      event.keys.forEach { key in
        guard let keyEnum = CustomEventField(rawValue: key),
              let mapping = customEventTransformations[keyEnum] else {
          return
        }
        if let section = mapping.section {
          if section == .customData {
            customData[mapping.field.rawValue] = transformValue(
              field: key,
              value: event[key] as Any
            )
          }
        } else if keyEnum == CustomEventField.eventName,
                  let eventName = event[key] as? String {
          transformedEvent[ConversionsAPICustomEventField.eventName.rawValue] = transformEventName(
            from: eventName)
        } else if keyEnum == CustomEventField.eventTime {
          transformedEvent[ConversionsAPICustomEventField.eventTime.rawValue] = transformValue(
            field: key,
            value: event[key] as Any
          )
        }
      }
      if !customData.isEmpty {
        transformedEvent[ConversionsAPISection.customData.rawValue] = customData
      }
      transformedEvents.append(transformedEvent)
    }
    return transformedEvents
  }

  // MARK: combine transformed data

  static func combineCommonFields(
    userData: [String: Any],
    appData: [String: Any],
    restOfData: [String: Any]
  ) -> [String: Any] {
    var converted = [String: Any]()
    converted[OtherEventConstants.actionSource.rawValue] = OtherEventConstants.app.rawValue
    converted[ConversionsAPISection.userData.rawValue] = userData
    converted[ConversionsAPISection.appData.rawValue] = appData
    converted.merge(restOfData) { $1 }
    return converted
  }

  static func combineAllTransformedDataForMobileAppInstall(
    commonFields: [String: Any],
    eventTime: Int?
  ) -> [[String: Any]]? {
    guard eventTime != nil else {
      return nil
    }
    var transformedEvent = [String: Any]()
    transformedEvent.merge(commonFields) { $1 }
    transformedEvent[ConversionsAPICustomEventField.eventName.rawValue] = OtherEventConstants.mobileAppInstall.rawValue
    transformedEvent[ConversionsAPICustomEventField.eventTime.rawValue] = eventTime
    return [transformedEvent]
  }

  static func combineAllTransformedDataForCustom(
    commonFields: [String: Any],
    customEvents: [[String: Any]]
  ) -> [[String: Any]]? {
    guard !customEvents.isEmpty else {
      return nil
    }
    var transformedEvents = [[String: Any]]()
    customEvents.forEach { customEvent in
      var customEventTransformed = [String: Any]()
      customEventTransformed.merge(commonFields) { $1 }
      customEventTransformed.merge(customEvent) { $1 }
      transformedEvents.append(customEventTransformed)
    }
    return transformedEvents
  }

  static func combineAllTransformedData(
    eventType: AppEventType,
    userData: [String: Any],
    appData: [String: Any],
    restOfData: [String: Any],
    customEvents: [[String: Any]],
    eventTime: Int?
  ) -> [[String: Any]]? {
    let commonFields = combineCommonFields(userData: userData, appData: appData, restOfData: restOfData)
    switch eventType {
    case .mobileAppInstall:
      return combineAllTransformedDataForMobileAppInstall(commonFields: commonFields, eventTime: eventTime)

    case .custom:
      return combineAllTransformedDataForCustom(commonFields: commonFields, customEvents: customEvents)
    default:
      return nil
    }
  }

  // MARK: main function

  static func conversionsAPICompatibleEvent(from parameters: [String: Any]) -> [[String: Any]]? {
    var userData = [String: Any]()
    var appData = [String: Any]()
    var restOfData = [String: Any]()
    var customEvents = [[String: Any]]()

    guard let eventType = splitAppEventParameters(
      from: parameters,
      userData: &userData,
      appData: &appData,
      restOfData: &restOfData,
      customEvents: &customEvents
    ), eventType != .other else {
      return nil
    }

    return combineAllTransformedData(
      eventType: eventType,
      userData: userData,
      appData: appData,
      restOfData: restOfData,
      customEvents: customEvents,
      eventTime: parameters[OtherEventConstants.installEventTime.rawValue] as? Int
    )
  }
}
