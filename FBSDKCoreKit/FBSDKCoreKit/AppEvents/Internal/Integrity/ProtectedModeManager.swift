/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

final class ProtectedModeManager: _AppEventsParameterProcessing {
  private var isEnabled = false
  private let standardParameters: Set<String> = [
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
  ]

  func enable() {
    isEnabled = true
  }

  func processParameters(
    _ parameters: [AppEvents.ParameterName: Any]?,
    eventName: AppEvents.Name
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

    return params
  }
}
