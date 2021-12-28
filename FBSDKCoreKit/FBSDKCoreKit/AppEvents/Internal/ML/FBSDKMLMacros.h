/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifndef FBSDKMLMacros_h
#define FBSDKMLMacros_h

// keys for ML
#define MODEL_REQUEST_INTERVAL                  (60 * 60 * 24 * 3)
#define MODEL_REQUEST_TIMESTAMP_KEY             @"com.facebook.sdk:FBSDKModelRequestTimestamp"

#define FBSDK_ML_MODEL_PATH                     @"models"
#define MODEL_INFO_KEY                          @"com.facebook.sdk:FBSDKModelInfo"
#define ASSET_URI_KEY                           @"asset_uri"
#define RULES_URI_KEY                           @"rules_uri"
#define THRESHOLDS_KEY                          @"thresholds"
#define USE_CASE_KEY                            @"use_case"
#define VERSION_ID_KEY                          @"version_id"
#define MODEL_DATA_KEY                          @"data"

#define MTMLKey                                 @"MTML"
#define MTMLTaskAppEventPredKey                 @"MTML_APP_EVENT_PRED"
#define MTMLTaskIntegrityDetectKey              @"MTML_INTEGRITY_DETECT"

// keys for Suggested Event
#define SUGGEST_EVENT_KEY                       @"SUGGEST_EVENT"
#define DENSE_FEATURE_KEY                       @"DENSE_FEATURE"
#define SUGGESTED_EVENT_OTHER                   @"other"

#endif /* FBSDKMLMacros_h */
