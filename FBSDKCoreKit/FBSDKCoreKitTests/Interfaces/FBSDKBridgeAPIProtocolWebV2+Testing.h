/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPIProtocolWebV2.h"

@protocol FBSDKServerConfigurationProviding;
@protocol FBSDKBridgeAPIProtocol;
@class FBSDKDialogConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIProtocolWebV2 (Testing)

@property (nullable, nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKBridgeAPIProtocol> nativeBridge;

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                       nativeBridge:(id<FBSDKBridgeAPIProtocol>)nativeBridge;

- (nullable NSURL *)_redirectURLWithActionID:(nullable NSString *)actionID
                                  methodName:(nullable NSString *)methodName
                                       error:(NSError **)errorRef;
- (nullable NSURL *)_requestURLForDialogConfiguration:(FBSDKDialogConfiguration *)dialogConfiguration
                                                error:(NSError **)errorRef;

@end

NS_ASSUME_NONNULL_END
