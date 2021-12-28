/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKConstants.h"

NSErrorDomain const FBSDKErrorDomain = @"com.facebook.sdk.core";

NSErrorUserInfoKey const FBSDKErrorArgumentCollectionKey = @"com.facebook.sdk:FBSDKErrorArgumentCollectionKey";
NSErrorUserInfoKey const FBSDKErrorArgumentNameKey = @"com.facebook.sdk:FBSDKErrorArgumentNameKey";
NSErrorUserInfoKey const FBSDKErrorArgumentValueKey = @"com.facebook.sdk:FBSDKErrorArgumentValueKey";
NSErrorUserInfoKey const FBSDKErrorDeveloperMessageKey = @"com.facebook.sdk:FBSDKErrorDeveloperMessageKey";
NSErrorUserInfoKey const FBSDKErrorLocalizedDescriptionKey = @"com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey";
NSErrorUserInfoKey const FBSDKErrorLocalizedTitleKey = @"com.facebook.sdk:FBSDKErrorLocalizedErrorTitleKey";

NSErrorUserInfoKey const FBSDKGraphRequestErrorKey = @"com.facebook.sdk:FBSDKGraphRequestErrorKey";
NSErrorUserInfoKey const FBSDKGraphRequestErrorCategoryKey = @"com.facebook.sdk:FBSDKGraphRequestErrorCategoryKey";
NSErrorUserInfoKey const FBSDKGraphRequestErrorGraphErrorCodeKey = @"com.facebook.sdk:FBSDKGraphRequestErrorGraphErrorCodeKey";
NSErrorUserInfoKey const FBSDKGraphRequestErrorGraphErrorSubcodeKey = @"com.facebook.sdk:FBSDKGraphRequestErrorGraphErrorSubcodeKey";
NSErrorUserInfoKey const FBSDKGraphRequestErrorHTTPStatusCodeKey = @"com.facebook.sdk:FBSDKGraphRequestErrorHTTPStatusCodeKey";
NSErrorUserInfoKey const FBSDKGraphRequestErrorParsedJSONResponseKey = @"com.facebook.sdk:FBSDKGraphRequestErrorParsedJSONResponseKey";
