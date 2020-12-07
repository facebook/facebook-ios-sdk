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

#import <Security/Security.h>

#import <CommonCrypto/CommonCrypto.h>

static FBSDKAuthenticationToken *g_currentAuthenticationToken;

NSString *const FBSDKAuthenticationTokenTokenStringCodingKey = @"FBSDKAuthenticationTokenTokenStringCodingKey";
NSString *const FBSDKAuthenticationTokenNonceCodingKey = @"FBSDKAuthenticationTokenNonceCodingKey";

NSNotificationName const FBSDKAuthenticationTokenDidChangeNotification = @"com.facebook.sdk.FBSDKAuthenticationTokenData.FBSDKAuthenticationTokenDidChangeNotification";
NSString *const FBSDKAuthenticationTokenChangeNewKey = @"FBSDKAuthenticationTokenChangeNew";
NSString *const FBSDKAuthenticationTokenChangeOldKey = @"FBSDKAuthenticationTokenChangeOld";

static long const MaxTimeSinceTokenIssued = 10 * 60; // 10 mins

@implementation FBSDKAuthenticationToken
{
  NSString *_cert;
  NSDictionary *_claims;
  NSDictionary *_header;
  NSString *_signature;
}

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
{
  if (!tokenString || tokenString.length == 0 || !nonce || nonce.length == 0) {
    return nil;
  }

  NSString *signature;
  NSDictionary *claims;
  NSDictionary *header;

  NSArray *segments = [tokenString componentsSeparatedByString:@"."];
  if (segments.count != 3) {
    return nil;
  }

  NSString *encodedHeader = [FBSDKTypeUtility array:segments objectAtIndex:0];
  NSString *encodedClaims = [FBSDKTypeUtility array:segments objectAtIndex:1];
  signature = [FBSDKTypeUtility array:segments objectAtIndex:2];

  if (![self verifySignature:signature
                      header:encodedHeader
                      claims:encodedClaims]) {
    return nil;
  }

  claims = [FBSDKAuthenticationToken validatedClaimsWithEncodedString:encodedClaims nonce:nonce];
  header = [FBSDKAuthenticationToken validatedHeaderWithEncodedString:encodedHeader];

  if (!claims || !header) {
    return nil;
  }

  return [self initWithTokenString:tokenString
                             nonce:nonce
                         signature:signature
                            claims:claims
                            header:header];
}

/// Do not call directly. Does not validate any of the data.
- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                          signature:(NSString *)signature
                             claims:(NSDictionary *)claims
                             header:(NSDictionary *)header
{
  if ((self = [super init])) {
    _tokenString = tokenString;
    _nonce = nonce;
    _signature = signature;
    _claims = claims;
    _header = header;
  }

  return self;
}

+ (FBSDKAuthenticationToken *)currentAuthenticationToken
{
  return g_currentAuthenticationToken;
}

+ (void)setCurrentAuthenticationToken:(FBSDKAuthenticationToken *)token
{
  if (token != g_currentAuthenticationToken) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [FBSDKTypeUtility dictionary:userInfo setObject:token forKey:FBSDKAuthenticationTokenChangeNewKey];
    [FBSDKTypeUtility dictionary:userInfo setObject:g_currentAuthenticationToken forKey:FBSDKAuthenticationTokenChangeOldKey];

    g_currentAuthenticationToken = token;
    [[self tokenCache] setAuthenticationToken:token];

    [[NSNotificationCenter defaultCenter] postNotificationName:FBSDKAuthenticationTokenDidChangeNotification
                                                        object:[self class]
                                                      userInfo:userInfo];
  }
}

+ (NSDictionary *)validatedClaimsWithEncodedString:(NSString *)encodedClaims nonce:(NSString *)nonce
{
  NSError *error;
  NSData *claimsData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationToken base64FromBase64Url:encodedClaims]];

  if (claimsData) {
    NSDictionary *claims = [FBSDKTypeUtility JSONObjectWithData:claimsData options:0 error:&error];
    if (!error) {
      long currentTime = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] longValue];

      // verify claims
      BOOL isFacebook = [claims[@"iss"] isKindOfClass:[NSString class]] && [[[NSURL URLWithString:claims[@"iss"]] host] isEqualToString:@"facebook.com"];
      BOOL audMatched = [claims[@"aud"] isKindOfClass:[NSString class]] && [claims[@"aud"] isEqualToString:[FBSDKSettings appID]];
      BOOL isExpired = [claims[@"exp"] isKindOfClass:[NSNumber class]] && [(NSNumber *)claims[@"exp"] longValue] <= currentTime;
      BOOL issuedRecently = [claims[@"iat"] isKindOfClass:[NSNumber class]] && [(NSNumber *)claims[@"iat"] longValue] >= currentTime - MaxTimeSinceTokenIssued;
      BOOL nonceMatched = [claims[@"nonce"] isKindOfClass:[NSString class]] && [claims[@"nonce"] isEqualToString:nonce];
      BOOL userIDValid = [claims[@"sub"] isKindOfClass:[NSString class]] && [claims[@"sub"] length] > 0;

      if (isFacebook && audMatched && !isExpired && issuedRecently && nonceMatched && userIDValid) {
        return claims;
      }
    }
  }

  return nil;
}

+ (NSDictionary *)validatedHeaderWithEncodedString:(NSString *)encodedHeader
{
  NSError *error;
  NSData *headerData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationToken base64FromBase64Url:encodedHeader]];

  if (headerData) {
    NSDictionary *header = [FBSDKTypeUtility JSONObjectWithData:headerData options:0 error:&error];
    if (!error && [header[@"alg"] isKindOfClass:[NSString class]] && [header[@"alg"] isEqualToString:@"RS256"]) {
      return header;
    }
  }

  return nil;
}

- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
{
#if DEBUG
  // skip signature checking for tests
  if (_skipSignatureVerification) {
    return YES;
  }
#endif

  NSData *signatureData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationToken base64FromBase64Url:signature]];
  NSString *signedString = [NSString stringWithFormat:@"%@.%@", header, claims];
  NSData *signedData = [signedString dataUsingEncoding:NSASCIIStringEncoding];
  SecKeyRef publicKey = [self getPublicKey];

  if (publicKey && signatureData && signedData) {
    OSStatus status = -1;

    size_t signatureBytesSize = SecKeyGetBlockSize(publicKey);
    const void *signatureBytes = signatureData.bytes;

    size_t digestSize = CC_SHA256_DIGEST_LENGTH;
    uint8_t digestBytes[digestSize];
    CC_SHA256(signedData.bytes, (CC_LONG)signedData.length, digestBytes);

    status = SecKeyRawVerify(
      publicKey,
      kSecPaddingPKCS1SHA256,
      digestBytes,
      digestSize,
      signatureBytes,
      signatureBytesSize
    );
    return status == errSecSuccess;
  }
  return NO;
}

- (NSString *)getCertificate
{
  // TODO(T79340096): replace with certificate retrieved from crypto keychain service
  return _cert;
}

- (SecKeyRef)getPublicKey
{
  SecKeyRef publicKey = nil;
  NSData *certData = [FBSDKBase64 decodeAsData:[self getCertificate]];
  SecCertificateRef cert = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certData);

  if (cert) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    OSStatus status = -1;
    SecTrustRef trust;

    status = SecTrustCreateWithCertificates(cert, policy, &trust);

    if (status == errSecSuccess && trust) {
      publicKey = SecTrustCopyPublicKey(trust);
    }

    CFRelease(policy);
    CFRelease(cert);
  }

  return publicKey;
}

+ (NSString *)base64FromBase64Url:(NSString *)base64Url
{
  NSString *base64 = [base64Url stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  base64 = [base64 stringByReplacingOccurrencesOfString:@"_" withString:@"/"];

  return base64;
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
                         signature:nil
                            claims:nil
                            header:nil];
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

static BOOL _skipSignatureVerification;

+ (void)setSkipSignatureVerification:(BOOL)value
{
  _skipSignatureVerification = value;
}

+ (instancetype)emptyInstance
{
  return [super new];
}

- (void)setCertificate:(NSString *)certificate
{
  _cert = certificate;
}

- (NSDictionary *)claims
{
  return _claims;
}

#endif

@end
