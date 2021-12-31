/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKBridgeAPIProtocol.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BridgeAPIProtocolWebV1)
@interface FBSDKBridgeAPIProtocolWebV1 : NSObject <FBSDKBridgeAPIProtocol>

@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic, readonly) id<FBSDKInternalUtility> internalUtility;

- (instancetype)initWithErrorFactory:(id<FBSDKErrorCreating>)errorFactory
                     internalUtility:(id<FBSDKInternalUtility>)internalUtility;

@end

NS_ASSUME_NONNULL_END

#endif
