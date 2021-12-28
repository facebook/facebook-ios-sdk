/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareBridgeAPIRequestFactory.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

@implementation FBSDKShareBridgeAPIRequestFactory

- (nullable id<FBSDKBridgeAPIRequest>)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                                scheme:(nonnull NSString *)scheme
                                                            methodName:(nullable NSString *)methodName
                                                            parameters:(nullable NSDictionary *)parameters
                                                              userInfo:(nullable NSDictionary *)userInfo
{
  return [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:protocolType
                                                          scheme:scheme
                                                      methodName:methodName
                                                      parameters:parameters
                                                        userInfo:userInfo];
}

@end

#endif
