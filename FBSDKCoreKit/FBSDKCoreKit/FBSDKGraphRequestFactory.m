/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestFactory.h"

#import "FBSDKGraphRequest+Internal.h"

@implementation FBSDKGraphRequestFactory

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                                      parameters:(NSDictionary<NSString *, id> *)parameters
                                                     tokenString:(NSString *)tokenString
                                                      HTTPMethod:(FBSDKHTTPMethod)method
                                                           flags:(FBSDKGraphRequestFlags)flags
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                           HTTPMethod:method
                                                flags:flags];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
                                                      parameters:(nonnull NSDictionary<NSString *, id> *)parameters
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:parameters];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
                                                      parameters:(nonnull NSDictionary<NSString *, id> *)parameters
                                                      HTTPMethod:(nonnull FBSDKHTTPMethod)method
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                           HTTPMethod:method];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(NSString *)graphPath
                                                      parameters:(NSDictionary<NSString *, id> *)parameters
                                                     tokenString:(NSString *)tokenString
                                                         version:(nullable NSString *)version
                                                      HTTPMethod:(FBSDKHTTPMethod)method
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                              version:version
                                           HTTPMethod:method];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
                                                      parameters:(nonnull NSDictionary<NSString *, id> *)parameters
                                                           flags:(FBSDKGraphRequestFlags)flags
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                                flags:flags];
}

@end
