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
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKBridgeAPIProtocol.h"
#import "FBSDKServerConfigurationProviding.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BridgeAPIProtocolWebV2)
@interface FBSDKBridgeAPIProtocolWebV2 : NSObject <FBSDKBridgeAPIProtocol>

@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKBridgeAPIProtocol> nativeBridge;
@property (nonatomic, readonly) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic, readonly) id<FBSDKInternalUtility> internalUtility;
@property (nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                       nativeBridge:(id<FBSDKBridgeAPIProtocol>)nativeBridge
                                       errorFactory:(id<FBSDKErrorCreating>)errorFactory
                                    internalUtility:(id<FBSDKInternalUtility>)internalUtility
                             infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider;

@end

NS_ASSUME_NONNULL_END

#endif
