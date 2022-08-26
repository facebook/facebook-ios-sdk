/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>
#import <FBSDKCoreKit/FBSDKBridgeAPIRequest.h>
#import <FBSDKCoreKit/FBSDKBridgeAPIRequestProtocol.h>
#import <FBSDKCoreKit/FBSDKURLScheme.h>

@protocol FBSDKInternalURLOpener;
@protocol FBSDKInternalUtility;
@protocol FBSDKSettings;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(_BridgeAPIRequest)
@interface FBSDKBridgeAPIRequest : NSObject <NSCopying, FBSDKBridgeAPIRequest>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (nullable instancetype)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                   scheme:(FBSDKURLScheme)scheme
                                               methodName:(nullable NSString *)methodName
                                               parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                 userInfo:(nullable NSDictionary<NSString *, id> *)userInfo;

@property (nonatomic, readonly, copy) NSString *actionID;
@property (nullable, nonatomic, readonly, copy) NSString *methodName;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *parameters;
@property (nonatomic, readonly, assign) FBSDKBridgeAPIProtocolType protocolType;
@property (nonatomic, readonly, copy) FBSDKURLScheme scheme;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *userInfo;

- (nullable NSURL *)requestURL:(NSError *_Nullable *)errorRef;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
+ (void)configureWithInternalURLOpener:(id<FBSDKInternalURLOpener>)internalURLOpener
                       internalUtility:(id<FBSDKInternalUtility>)internalUtility
                              settings:(id<FBSDKSettings>)settings
NS_SWIFT_NAME(configure(internalURLOpener:internalUtility:settings:));

@end

NS_ASSUME_NONNULL_END

#endif
