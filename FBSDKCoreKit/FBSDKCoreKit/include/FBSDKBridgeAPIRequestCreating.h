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

NS_SWIFT_NAME(BridgeAPIRequestCreating)
@protocol FBSDKBridgeAPIRequestCreating

- (nullable id<FBSDKBridgeAPIRequest>)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                                scheme:(NSString *)scheme
                                                            methodName:(nullable NSString *)methodName
                                                         methodVersion:(nullable NSString *)methodVersion
                                                            parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                              userInfo:(nullable NSDictionary<NSString *, id> *)userInfo;

@end

NS_ASSUME_NONNULL_END

#endif
