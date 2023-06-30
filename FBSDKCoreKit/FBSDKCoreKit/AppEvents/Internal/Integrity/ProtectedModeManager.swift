/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKProtectedModeManager)
final class ProtectedModeManager: NSObject, _AppEventsParameterProcessing {
  private var isEnabled = false
  private let standardParametersDefault: Set<String> = [
    "_currency",
    "_valueToSum",
    "fb_availability",
    "fb_body_style",
    "fb_checkin_date",
    "fb_checkout_date",
    "fb_city",
    "fb_condition_of_vehicle",
    "fb_content_category",
    "fb_content_ids",
    "fb_content_name",
    "fb_content_type",
    "fb_contents",
    "fb_country",
    "fb_currency",
    "fb_delivery_category",
    "fb_departing_arrival_date",
    "fb_departing_departure_date",
    "fb_destination_airport",
    "fb_destination_ids",
    "fb_dma_code",
    "fb_drivetrain",
    "fb_exterior_color",
    "fb_fuel_type",
    "fb_hotel_score",
    "fb_interior_color",
    "fb_lease_end_date",
    "fb_lease_start_date",
    "fb_listing_type",
    "fb_make",
    "fb_mileage.unit",
    "fb_mileage.value",
    "fb_model",
    "fb_neighborhood",
    "fb_num_adults",
    "fb_num_children",
    "fb_num_infants",
    "fb_num_items",
    "fb_order_id",
    "fb_origin_airport",
    "fb_postal_code",
    "fb_predicted_ltv",
    "fb_preferred_baths_range",
    "fb_preferred_beds_range",
    "fb_preferred_neighborhoods",
    "fb_preferred_num_stops",
    "fb_preferred_price_range",
    "fb_preferred_star_ratings",
    "fb_price",
    "fb_property_type",
    "fb_region",
    "fb_returning_arrival_date",
    "fb_returning_departure_date",
    "fb_search_string",
    "fb_state_of_vehicle",
    "fb_status",
    "fb_suggested_destinations",
    "fb_suggested_home_listings",
    "fb_suggested_hotels",
    "fb_suggested_jobs",
    "fb_suggested_local_service_businesses",
    "fb_suggested_location_based_items",
    "fb_suggested_vehicles",
    "fb_transmission",
    "fb_travel_class",
    "fb_travel_end",
    "fb_travel_start",
    "fb_trim",
    "fb_user_bucket",
    "fb_value",
    "fb_vin",
    "fb_year",
    "lead_event_source",
    "predicted_ltv",
    "product_catalog_id",
    "app_user_id",
    "appVersion",
    "_eventName",
    "_eventName_md5",
    "_currency",
    "_implicitlyLogged",
    "_inBackground",
    "_isTimedEvent",
    "_logTime",
    "fb_order_id",
    "_session_id",
    "_ui",
    "_valueToSum",
    "_valueToUpdate",
    "_is_fb_codeless",
    "_is_suggested_event",
    "_fb_pixel_referral_id",
    "fb_pixel_id",
    "trace_id",
    "user_agent",
    "subscription_id",
    "predicted_ltv",
    "event_id",
    "_restrictedParams",
    "_onDeviceParams",
    "purchase_valid_result_type",
    "core_lib_included",
    "login_lib_included",
    "share_lib_included",
    "place_lib_included",
    "messenger_lib_included",
    "applinks_lib_included",
    "marketing_lib_included",
    "_codeless_action",
    "sdk_initialized",
    "billing_client_lib_included",
    "billing_service_lib_included",
    "user_data_keys",
    "device_push_token",
    "fb_mobile_pckg_fp",
    "fb_mobile_app_cert_hash",
    "aggregate_id",
    "anonymous_id",
    "campaign_ids",
    "fb_post_attachment",
    "receipt_data",
    "ad_type",
    "fb_content",
    "fb_content_id",
    "fb_content_type",
    "fb_currency",
    "fb_description",
    "fb_level",
    "fb_max_rating_value",
    "fb_num_items",
    "fb_order_id",
    "fb_payment_info_available",
    "fb_registration_method",
    "fb_search_string",
    "fb_success",
    "pm",
    "_audiencePropertyIds",
    "cs_maca",
  ]
  private var standardParameters: Set<String> = []

  var configuredDependencies: ObjectDependencies?

  var defaultDependencies: ObjectDependencies? = .init(
    serverConfigurationProvider: _ServerConfigurationManager.shared
  )

  func enable() {
    guard let dependencies = try? getDependencies() else {
      return
    }

    if let standardParamsList = dependencies.serverConfigurationProvider
      .cachedServerConfiguration()
      .protectedModeRules?["standard_params"] as? [String] {
      if !standardParamsList.isEmpty {
        standardParameters = Set(standardParamsList)
      }
    }

    if standardParameters.isEmpty {
      standardParameters = standardParametersDefault
    }
    isEnabled = true
  }

  @objc func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name?
  ) -> [AppEvents.ParameterName: Any]? {
    guard isEnabled,
          let parameters = parameters,
          !parameters.isEmpty
    else {
      return parameters
    }

    var params = parameters
    parameters.keys.forEach { appEventsParameterName in
      if !standardParameters.contains(appEventsParameterName.rawValue) {
        params.removeValue(forKey: appEventsParameterName)
      }
    }
    let pmKey = AppEvents.ParameterName(rawValue: "pm")
    params[pmKey] = true
    return params
  }
}

extension ProtectedModeManager: DependentAsObject {
  struct ObjectDependencies {
    var serverConfigurationProvider: _ServerConfigurationProviding
  }
}
