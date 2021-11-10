/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPIRequest+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIRequest (Testing)

// UNCRUSTIFY_FORMAT_OFF
+ (void)configureWithInternalURLOpener:(nonnull id<FBSDKInternalURLOpener>)internalURLOpener
                       internalUtility:(nonnull id<FBSDKInternalUtility>)internalUtility
                              settings:(nonnull id<FBSDKSettings>)settings
NS_SWIFT_NAME(configure(internalURLOpener:internalUtility:settings:));
// UNCRUSTIFY_FORMAT_ON

#if FBTEST && DEBUG
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END
