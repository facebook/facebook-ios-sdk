/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>
#import "FBSDKAppLinkURLKeys.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const FBSDKAppLinkDataParameterName = @"al_applink_data";
NSString *const FBSDKAppLinkTargetKeyName = @"target_url";
NSString *const FBSDKAppLinkUserAgentKeyName = @"user_agent";
NSString *const FBSDKAppLinkExtrasKeyName = @"extras";
NSString *const FBSDKAppLinkVersionKeyName = @"version";
NSString *const FBSDKAppLinkRefererAppLink = @"referer_app_link";
NSString *const FBSDKAppLinkRefererAppName = @"app_name";
NSString *const FBSDKAppLinkRefererUrl = @"url";

NS_ASSUME_NONNULL_END

#endif
