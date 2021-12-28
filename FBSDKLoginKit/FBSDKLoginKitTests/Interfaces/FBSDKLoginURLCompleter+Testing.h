/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLoginURLCompleter.h"
#import "FBSDKProfileCreating.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginURLCompleter (Testing)

@property (class, nonatomic, assign) id<FBSDKProfileCreating> profileFactory;
@property (nonatomic, readonly) FBSDKLoginCompletionParameters *parameters;

+ (FBSDKProfile *)profileWithClaims:(FBSDKAuthenticationTokenClaims *)claims;

+ (void)reset;

+ (NSDateFormatter *)dateFormatter;

@end

NS_ASSUME_NONNULL_END
