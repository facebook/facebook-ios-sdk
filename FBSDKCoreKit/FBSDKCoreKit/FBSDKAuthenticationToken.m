// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKAuthenticationToken.h"

#import <Foundation/Foundation.h>

#if SWIFT_PACKAGE
@import FBSDKCoreKit;
#else
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#endif

#ifdef FBSDKCOCOAPODS
 #import <FBSDKCoreKit/FBSDKCoreKit+Internal.h>
#else
 #import "FBSDKCoreKit+Internal.h"
#endif

static FBSDKAuthenticationToken *g_currentAuthenticationToken;

NSString *const FBSDKAuthenticationTokenTokenStringCodingKey = @"FBSDKAuthenticationTokenTokenStringCodingKey";
NSString *const FBSDKAuthenticationTokenNonceCodingKey = @"FBSDKAuthenticationTokenNonceCodingKey";

NSNotificationName const FBSDKAuthenticationTokenDidChangeNotification = @"com.facebook.sdk.FBSDKAuthenticationTokenData.FBSDKAuthenticationTokenDidChangeNotification";
NSString *const FBSDKAuthenticationTokenChangeNewKey = @"FBSDKAuthenticationTokenChangeNew";
NSString *const FBSDKAuthenticationTokenChangeOldKey = @"FBSDKAuthenticationTokenChangeOld";

@implementation FBSDKAuthenticationToken
{
  NSDictionary *_claims;
}

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                             claims:(NSDictionary *)claims
{
  if ((self = [super init])) {
    _tokenString = tokenString;
    _nonce = nonce;
    _claims = claims;
  }
  return self;
}

+ (FBSDKAuthenticationToken *)currentAuthenticationToken
{
  return g_currentAuthenticationToken;
}

+ (void)setCurrentAuthenticationToken:(FBSDKAuthenticationToken *)token
{
  [self setCurrentAuthenticationToken:token shouldPostNotification:YES];
}

+ (void)setCurrentAuthenticationToken:(FBSDKAuthenticationToken *)token
               shouldPostNotification:(BOOL)shouldPostNotification
{
  if (token != g_currentAuthenticationToken) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [FBSDKTypeUtility dictionary:userInfo setObject:token forKey:FBSDKAuthenticationTokenChangeNewKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:g_currentAuthenticationToken forKey:FBSDKAuthenticationTokenChangeOldKey];

    g_currentAuthenticationToken = token;
    [[self tokenCache] setAuthenticationToken:token];

    if (shouldPostNotification) {
      [[NSNotificationCenter defaultCenter] postNotificationName:FBSDKAuthenticationTokenDidChangeNotification
                                                          object:[self class]
                                                        userInfo:userInfo];
    }
  }
}

#pragma mark Storage

+ (id<FBSDKTokenCaching>)tokenCache
{
  return FBSDKSettings.tokenCache;
}

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *tokenString = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKAuthenticationTokenTokenStringCodingKey];
  NSString *nonce = [decoder decodeObjectOfClass:NSString.class forKey:FBSDKAuthenticationTokenNonceCodingKey];

  return [self initWithTokenString:tokenString
                             nonce:nonce
                            claims:nil];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.tokenString forKey:FBSDKAuthenticationTokenTokenStringCodingKey];
  [encoder encodeObject:self.nonce forKey:FBSDKAuthenticationTokenNonceCodingKey];
}

#pragma mark - Test methods

#if DEBUG

+ (void)resetCurrentAuthenticationTokenCache
{
  g_currentAuthenticationToken = nil;
}

- (NSDictionary *)claims
{
  return _claims;
}

#endif

@end
