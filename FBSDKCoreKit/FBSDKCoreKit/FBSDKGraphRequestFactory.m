/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                      HTTPMethod:(nullable FBSDKHTTPMethod)method
                                                           flags:(FBSDKGraphRequestFlags)flags
                                                    forAppEvents:(BOOL)forAppEvents 
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                           HTTPMethod:method
                                                flags:flags
                                         forAppEvents:forAppEvents];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                         version:(nullable NSString *)version
                                                      HTTPMethod:(nonnull FBSDKHTTPMethod)method
                                                    forAppEvents:(BOOL)forAppEvents 
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                              version:version
                                           HTTPMethod:method
                                         forAppEvents:forAppEvents];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                      HTTPMethod:(nonnull FBSDKHTTPMethod)method
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath 
                                           parameters:parameters
                                           HTTPMethod:method
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                      HTTPMethod:(nullable FBSDKHTTPMethod)method
                                                           flags:(FBSDKGraphRequestFlags)flags
                                                    forAppEvents:(BOOL)forAppEvents
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                           HTTPMethod:method
                                                flags:flags
                                         forAppEvents:forAppEvents
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                      HTTPMethod:(nullable FBSDKHTTPMethod)method
                                                           flags:(FBSDKGraphRequestFlags)flags
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                           HTTPMethod:method
                                                flags:flags
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                     tokenString:(nullable NSString *)tokenString
                                                         version:(nullable NSString *)version
                                                      HTTPMethod:(nonnull FBSDKHTTPMethod)method forAppEvents:(BOOL)forAppEvents
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                          tokenString:tokenString
                                              version:version
                                           HTTPMethod:method
                                         forAppEvents:forAppEvents
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}


- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix
{ 
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}

- (nonnull id<FBSDKGraphRequest>)createGraphRequestWithGraphPath:(nonnull NSString *)graphPath 
                                                      parameters:(nonnull NSDictionary<NSString *,id> *)parameters
                                                           flags:(FBSDKGraphRequestFlags)flags
                               useAlternativeDefaultDomainPrefix:(BOOL)useAlternativeDefaultDomainPrefix 
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath
                                           parameters:parameters
                                                flags:flags
                    useAlternativeDefaultDomainPrefix:useAlternativeDefaultDomainPrefix];
}




@end
