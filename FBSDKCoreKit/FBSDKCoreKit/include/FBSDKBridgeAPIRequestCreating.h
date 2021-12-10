/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKBridgeAPIProtocolType.h>

@protocol FBSDKBridgeAPIRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIRequestCreating)
@protocol FBSDKBridgeAPIRequestCreating

- (nullable id<FBSDKBridgeAPIRequest>)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                                scheme:(NSString *)scheme
                                                            methodName:(nullable NSString *)methodName
                                                            parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                              userInfo:(nullable NSDictionary<NSString *, id> *)userInfo;

@end

NS_ASSUME_NONNULL_END

#endif
