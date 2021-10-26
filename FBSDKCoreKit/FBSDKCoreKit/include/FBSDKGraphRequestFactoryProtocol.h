/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestFlags.h>

@protocol FBSDKGraphRequest;

typedef NSString *const FBSDKHTTPMethod NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(HTTPMethod);

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type not intended for use outside of the SDKs.

Describes anything that can provide instances of `GraphRequestProtocol`
 */
NS_SWIFT_NAME(GraphRequestFactoryProtocol)
@protocol FBSDKGraphRequestFactory

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters
                                             tokenString:(nullable NSString *)tokenString
                                              HTTPMethod:(nullable FBSDKHTTPMethod)method
                                                   flags:(FBSDKGraphRequestFlags)flags;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters
                                              HTTPMethod:(FBSDKHTTPMethod)method;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters
                                             tokenString:(nullable NSString *)tokenString
                                                 version:(nullable NSString *)version
                                              HTTPMethod:(FBSDKHTTPMethod)method;

- (id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                              parameters:(NSDictionary<NSString *, id> *)parameters
                                                   flags:(FBSDKGraphRequestFlags)flags;

@end

NS_ASSUME_NONNULL_END
