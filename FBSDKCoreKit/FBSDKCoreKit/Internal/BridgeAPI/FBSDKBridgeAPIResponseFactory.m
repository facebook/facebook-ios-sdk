/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIResponseFactory.h"

#import "FBSDKBridgeAPIRequestProtocol.h"
#import "FBSDKBridgeAPIResponse.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKBridgeAPIResponseFactory

- (FBSDKBridgeAPIResponse *)createResponseCancelledWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
{
  return [FBSDKBridgeAPIResponse bridgeAPIResponseCancelledWithRequest:request];
}

- (FBSDKBridgeAPIResponse *)createResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                error:(NSError *)error
{
  return [FBSDKBridgeAPIResponse bridgeAPIResponseWithRequest:request
                                                        error:error];
}

- (nullable FBSDKBridgeAPIResponse *)createResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                   responseURL:(NSURL *)responseURL
                                             sourceApplication:(nullable NSString *)sourceApplication
                                                         error:(NSError *__autoreleasing _Nullable *_Nullable)errorRef
{
  return [FBSDKBridgeAPIResponse bridgeAPIResponseWithRequest:request
                                                  responseURL:responseURL
                                            sourceApplication:sourceApplication
                                                        error:errorRef];
}

@end

NS_ASSUME_NONNULL_END

#endif
