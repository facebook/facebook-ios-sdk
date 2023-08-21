/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

extension AppEvents.ParameterName {
  static let errorMessage = AppEvents.ParameterName("fb_dialog_outcome_error_message")
  static let outcome = AppEvents.ParameterName("fb_dialog_outcome")
  static let shareContentType = AppEvents.ParameterName("fb_dialog_share_content_type")
  static let mode = AppEvents.ParameterName("fb_dialog_mode")
  static let shareContentPageID = AppEvents.ParameterName("fb_dialog_share_content_page_id")
  static let shareContentUUID = AppEvents.ParameterName("fb_dialog_share_content_uuid")
}

enum ShareAppEventsParameters {
  enum DialogOutcomeValue {
    static let cancelled = "Cancelled"
    static let completed = "Completed"
    static let failed = "Failed"
  }

  enum ContentTypeValue {
    static let status = "Status"
    static let photo = "Photo"
    static let video = "Video"
    static let camera = "Camera"
    static let unknown = "Unknown"
  }
}
