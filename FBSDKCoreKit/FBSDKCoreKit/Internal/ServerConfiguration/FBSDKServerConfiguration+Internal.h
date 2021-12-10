/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKServerConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameDefault;
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameSharing;

FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationFeatureUseNativeFlow;
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationFeatureUseSafariViewController;

@interface FBSDKServerConfiguration (Internal)

+ (FBSDKServerConfiguration *)defaultServerConfigurationForAppID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
