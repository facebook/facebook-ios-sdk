/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKAppEventsState;

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_AppEventsStateProviding)
@protocol FBSDKAppEventsStateProviding

// UNCRUSTIFY_FORMAT_OFF
- (FBSDKAppEventsState *)createStateWithToken:(NSString *)tokenString appID:(NSString *)appID
NS_SWIFT_NAME(createState(tokenString:appID:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
