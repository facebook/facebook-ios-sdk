/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGraphRequest (Internal)

@property (class, nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) Class<FBSDKTokenStringProviding> accessTokenProvider;

@property (nonatomic, readonly, getter = isGraphErrorRecoveryDisabled) BOOL graphErrorRecoveryDisabled;
@property (nonatomic, readonly) BOOL hasAttachments;

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(nullable NSDictionary<NSString *, id> *)parameters
                      tokenString:(nullable NSString *)tokenString
                       HTTPMethod:(nullable NSString *)HTTPMethod
                            flags:(FBSDKGraphRequestFlags)flags
    graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)factory;

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(NSString *)method
                          version:(NSString *)version
                            flags:(FBSDKGraphRequestFlags)flags
    graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)factory;

+ (BOOL)isAttachment:(id)item;
+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(nullable NSDictionary<NSString *, id> *)params
                httpMethod:(nullable NSString *)httpMethod
                  forBatch:(BOOL)forBatch;

@end

NS_ASSUME_NONNULL_END
