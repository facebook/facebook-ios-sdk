/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

@protocol FBSDKBridgeAPIRequest;
@class FBSDKBridgeAPIResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
typedef void (^ FBSDKBridgeAPIResponseBlock)(FBSDKBridgeAPIResponse *response)
NS_SWIFT_NAME(BridgeAPIResponseBlock);

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
NS_SWIFT_NAME(BridgeAPIResponse)
@interface FBSDKBridgeAPIResponse : NSObject <NSCopying, NSObject>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request error:(NSError *)error;
+ (nullable instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                          responseURL:(NSURL *)responseURL
                                    sourceApplication:(nullable NSString *)sourceApplication
                                                error:(NSError *__autoreleasing *)errorRef;
+ (instancetype)bridgeAPIResponseCancelledWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request;

@property (nonatomic, readonly, getter = isCancelled, assign) BOOL cancelled;
@property (nullable, nonatomic, readonly, copy) NSError *error;
@property (nonatomic, readonly, copy) NSObject<FBSDKBridgeAPIRequest> *request;
@property (nullable, nonatomic, readonly, copy) NSDictionary<NSString *, id> *responseParameters;

@end

NS_ASSUME_NONNULL_END

#endif
