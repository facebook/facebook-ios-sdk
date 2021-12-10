/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIRequestFactory.h"

#import "FBSDKBridgeAPIRequest.h"

@implementation FBSDKBridgeAPIRequestFactory

- (nullable id<FBSDKBridgeAPIRequest>)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                                scheme:(NSString *)scheme
                                                            methodName:(NSString *)methodName
                                                            parameters:(NSDictionary *)parameters
                                                              userInfo:(NSDictionary *)userInfo
{
  return [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:protocolType
                                                          scheme:scheme
                                                      methodName:methodName
                                                      parameters:parameters
                                                        userInfo:userInfo];
}

@end

#endif
