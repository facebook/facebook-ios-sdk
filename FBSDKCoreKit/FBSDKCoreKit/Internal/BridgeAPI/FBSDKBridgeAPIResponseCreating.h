/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

@protocol FBSDKBridgeAPIRequest;
@class FBSDKBridgeAPIResponse;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BridgeAPIResponseCreating)
@protocol FBSDKBridgeAPIResponseCreating

- (FBSDKBridgeAPIResponse *)createResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                error:(NSError *)error;

- (nullable FBSDKBridgeAPIResponse *)createResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                                   responseURL:(NSURL *)responseURL
                                             sourceApplication:(nullable NSString *)sourceApplication
                                                         error:(NSError *__autoreleasing *)errorRef;

- (FBSDKBridgeAPIResponse *)createResponseCancelledWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request;

@end

NS_ASSUME_NONNULL_END

#endif
