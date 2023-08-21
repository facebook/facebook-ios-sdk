/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKBridgeAPIProtocol.h"
#import "FBSDKBridgeAPIRequest.h"
#import "FBSDKInternalUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIRequest ()

@property (class, nullable, nonatomic) id<FBSDKInternalURLOpener> internalURLOpener;
@property (class, nullable, nonatomic) id<FBSDKInternalUtility> internalUtility;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;

@property (nonatomic, readwrite) id<FBSDKBridgeAPIProtocol> protocol;

// UNCRUSTIFY_FORMAT_OFF
- (nullable instancetype)initWithProtocol:(nullable id<FBSDKBridgeAPIProtocol>)protocol
                             protocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                   scheme:(FBSDKURLScheme)scheme
                               methodName:(nullable NSString *)methodName
                               parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                 userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
NS_DESIGNATED_INITIALIZER
NS_SWIFT_NAME(init(protocol:protocolType:scheme:methodName:parameters:userInfo:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
