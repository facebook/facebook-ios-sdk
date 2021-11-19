/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKGamingPayloadDelegate.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kGamingPayload;
extern NSString *const kGamingPayloadGameRequestID;
extern NSString *const kGamingPayloadContextTokenID;

NS_SWIFT_NAME(GamingPayloadObserver)
@interface FBSDKGamingPayloadObserver : NSObject

@property (nonatomic, weak) id<FBSDKGamingPayloadDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<FBSDKGamingPayloadDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
