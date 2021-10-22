/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationToken.h"
#import "FBSDKAuthenticationToken+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAuthenticationTokenClaims+Internal.h"

static FBSDKAuthenticationToken *g_currentAuthenticationToken;
static id<FBSDKTokenCaching> g_tokenCache;

NSString *const FBSDKAuthenticationTokenTokenStringCodingKey = @"FBSDKAuthenticationTokenTokenStringCodingKey";
NSString *const FBSDKAuthenticationTokenNonceCodingKey = @"FBSDKAuthenticationTokenNonceCodingKey";
NSString *const FBSDKAuthenticationTokenGraphDomainCodingKey = @"FBSDKAuthenticationTokenGraphDomainCodingKey";

@interface FBSDKAuthenticationToken ()

@property (nonatomic) NSString *jti;

@end

@implementation FBSDKAuthenticationToken

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                        graphDomain:(NSString *)graphDomain
{
  if ((self = [super init])) {
    _tokenString = tokenString;
    _nonce = nonce;
    _graphDomain = graphDomain;
  }
  return self;
}

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
{
  return [self initWithTokenString:tokenString
                             nonce:nonce
                       graphDomain:@"facebook"];
}

+ (nullable FBSDKAuthenticationToken *)currentAuthenticationToken
{
  return g_currentAuthenticationToken;
}

+ (void)setCurrentAuthenticationToken:(nullable FBSDKAuthenticationToken *)token
{
  if (token != g_currentAuthenticationToken) {
    g_currentAuthenticationToken = token;
    self.tokenCache.authenticationToken = token;
  }
}

- (nullable FBSDKAuthenticationTokenClaims *)claims
{
  NSArray *segments = [_tokenString componentsSeparatedByString:@"."];
  if (segments.count != 3) {
    return nil;
  }
  NSString *encodedClaims = [FBSDKTypeUtility array:segments objectAtIndex:1];
  return [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:_nonce];
}

#pragma mark - Storage

+ (id<FBSDKTokenCaching>)tokenCache
{
  return g_tokenCache;
}

+ (void)setTokenCache:(id<FBSDKTokenCaching>)cache
{
  if (g_tokenCache != cache) {
    g_tokenCache = cache;
  }
}

+ (void)resetTokenCache
{
  g_tokenCache = nil;
}

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *tokenString = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKAuthenticationTokenTokenStringCodingKey];
  NSString *nonce = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKAuthenticationTokenNonceCodingKey];
  NSString *graphDomain = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKAuthenticationTokenGraphDomainCodingKey];

  return [self initWithTokenString:tokenString
                             nonce:nonce
                       graphDomain:graphDomain];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.tokenString forKey:FBSDKAuthenticationTokenTokenStringCodingKey];
  [encoder encodeObject:self.nonce forKey:FBSDKAuthenticationTokenNonceCodingKey];
  [encoder encodeObject:_graphDomain forKey:FBSDKAuthenticationTokenGraphDomainCodingKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // we're immutable.
  return self;
}

#pragma mark - Test methods

#if DEBUG && FBTEST

+ (void)resetCurrentAuthenticationTokenCache
{
  g_currentAuthenticationToken = nil;
}

#endif

@end
