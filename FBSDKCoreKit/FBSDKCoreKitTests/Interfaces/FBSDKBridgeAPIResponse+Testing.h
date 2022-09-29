/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKBridgeAPIResponse (Testing)

+ (nullable instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                          responseURL:(NSURL *)responseURL
                                    sourceApplication:(NSString *)sourceApplication
                                    osVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)comparer
                                                error:(NSError *__autoreleasing *)errorRef;

- (instancetype)initWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
             responseParameters:(NSDictionary<NSString *, id> *)responseParameters
                      cancelled:(BOOL)cancelled
                          error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
