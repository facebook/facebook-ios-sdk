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

#import "FBSDKAuthenticationTokenFactory.h"

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

#import "FBSDKSessionProviding.h"

static long const MaxTimeSinceTokenIssued = 10 * 60; // 10 mins

static NSString *const FBSDKDefaultDomain = @"facebook.com";
static NSString *const FBSDKBeginCertificate = @"-----BEGIN CERTIFICATE-----";
static NSString *const FBSDKEndCertificate = @"-----END CERTIFICATE-----";

typedef void (^FBSDKPublicCertCompletionBlock)(SecCertificateRef cert);
typedef void (^FBSDKPublicKeyCompletionBlock)(SecKeyRef key);
typedef void (^FBSDKVerifySignatureCompletionBlock)(BOOL success);

@interface FBSDKAuthenticationToken (FactoryInitializer)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                             claims:(NSDictionary *)claims;

@end

@implementation FBSDKAuthenticationTokenFactory
{
  NSString *_cert;
  NSDictionary *_claims;
  NSDictionary *_header;
  NSString *_signature;
  id<FBSDKSessionProviding> _sessionProvider;
}

- (instancetype)init
{
  self = [self initWithSessionProvider:NSURLSession.sharedSession];
  return self;
}

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider
{
  if ((self = [super init])) {
    _sessionProvider = sessionProvider;
  }
  return self;
}

- (void)createTokenFromTokenString:(NSString *_Nonnull)tokenString
                             nonce:(NSString *)nonce
                        completion:(FBSDKAuthenticationTokenBlock)completion
{
  if (tokenString.length == 0 || nonce.length == 0) {
    completion(nil);
    return;
  }

  NSString *signature;
  NSDictionary *claims;
  NSDictionary *header;

  NSArray *segments = [tokenString componentsSeparatedByString:@"."];
  if (segments.count != 3) {
    completion(nil);
    return;
  }

  NSString *encodedHeader = [FBSDKTypeUtility array:segments objectAtIndex:0];
  NSString *encodedClaims = [FBSDKTypeUtility array:segments objectAtIndex:1];
  signature = [FBSDKTypeUtility array:segments objectAtIndex:2];

  claims = [FBSDKAuthenticationTokenFactory validatedClaimsWithEncodedString:encodedClaims nonce:nonce];

  // TODO: Make header a qualified object - T81294823
  header = [FBSDKAuthenticationTokenFactory validatedHeaderWithEncodedString:encodedHeader];
  NSString *certificateKey = [FBSDKTypeUtility dictionary:header
                                             objectForKey:@"kid"
                                                   ofType:NSString.class];

  if (!claims || !header || !certificateKey) {
    completion(nil);
    return;
  }

  [self verifySignature:signature
                 header:encodedHeader
                 claims:encodedClaims
         certificateKey:certificateKey
             completion:^(BOOL success) {
               if (success) {
                 FBSDKAuthenticationToken *token = [[FBSDKAuthenticationToken alloc] initWithTokenString:tokenString nonce:nonce claims:claims];
                 completion(token);
               } else {
                 completion(nil);
               }
             }];
}

+ (NSDictionary *)validatedClaimsWithEncodedString:(NSString *)encodedClaims nonce:(NSString *)nonce
{
  NSError *error;
  NSData *claimsData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationTokenFactory base64FromBase64Url:encodedClaims]];

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
      BOOL hasJTI = [claims[@"jti"] isKindOfClass:[NSString class]] && [claims[@"jti"] length] > 0;

      if (isFacebook && audMatched && !isExpired && issuedRecently && nonceMatched && userIDValid && hasJTI) {
        return claims;
      }
    }
  }

  return nil;
}

+ (NSDictionary *)validatedHeaderWithEncodedString:(NSString *)encodedHeader
{
  NSError *error;
  NSData *headerData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationTokenFactory base64FromBase64Url:encodedHeader]];

  if (headerData) {
    NSDictionary *header = [FBSDKTypeUtility JSONObjectWithData:headerData options:0 error:&error];
    if (!error && [header[@"alg"] isKindOfClass:[NSString class]] && [header[@"alg"] isEqualToString:@"RS256"]) {
      return header;
    }
  }

  return nil;
}

- (void)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
         certificateKey:(NSString *)certificateKey
             completion:(FBSDKVerifySignatureCompletionBlock)completion
{
#if DEBUG
  // skip signature checking for tests
  if (_skipSignatureVerification && completion) {
    completion(YES);
  }
#endif

  NSData *signatureData = [FBSDKBase64 decodeAsData:[FBSDKAuthenticationTokenFactory
                                                     base64FromBase64Url:signature]];
  NSString *signedString = [NSString stringWithFormat:@"%@.%@", header, claims];
  NSData *signedData = [signedString dataUsingEncoding:NSASCIIStringEncoding];
  [self getPublicKeyWithCertificateKey:certificateKey
                            completion:^(SecKeyRef key) {
                              if (key && signatureData && signedData) {
                                size_t signatureBytesSize = SecKeyGetBlockSize(key);
                                const void *signatureBytes = signatureData.bytes;

                                size_t digestSize = CC_SHA256_DIGEST_LENGTH;
                                uint8_t digestBytes[digestSize];
                                CC_SHA256(signedData.bytes, (CC_LONG)signedData.length, digestBytes);

                                OSStatus status = SecKeyRawVerify(
                                  key,
                                  kSecPaddingPKCS1SHA256,
                                  digestBytes,
                                  digestSize,
                                  signatureBytes,
                                  signatureBytesSize
                                );
                                fb_dispatch_on_main_thread(^{
                                  completion(status == errSecSuccess);
                                });
                              } else {
                                fb_dispatch_on_main_thread(^{
                                  completion(NO);
                                });
                              }
                            }];
}

- (void)getPublicKeyWithCertificateKey:(NSString *)certificateKey
                            completion:(FBSDKPublicKeyCompletionBlock)completion
{
  [self getCertificateWithKey:certificateKey
                   completion:^(SecCertificateRef cert) {
                     SecKeyRef publicKey = nil;

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

                     completion(publicKey);
                   }];
}

- (void)getCertificateWithKey:(NSString *)certificateKey
                   completion:(FBSDKPublicCertCompletionBlock)completion
{
  NSURLRequest *request = [NSURLRequest requestWithURL:[self _certificateEndpoint]];
  [[_sessionProvider dataTaskWithRequest:request
                       completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
                         if (error || !data) {
                           return completion(nil);
                         }

                         if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                           if (httpResponse.statusCode != 200) {
                             return completion(nil);
                           }
                         }

                         SecCertificateRef result = NULL;
                         NSDictionary *certs = [FBSDKTypeUtility JSONObjectWithData:data options:0 error:nil];
                         NSString *certString = [FBSDKTypeUtility dictionary:certs objectForKey:certificateKey ofType:NSString.class];
                         if (!certString) {
                           return completion(nil);
                         }
                         certString = [certString stringByReplacingOccurrencesOfString:FBSDKBeginCertificate withString:@""];
                         certString = [certString stringByReplacingOccurrencesOfString:FBSDKEndCertificate withString:@""];
                         certString = [certString stringByReplacingOccurrencesOfString:@"\n" withString:@""];

                         NSData *secCertificateData = [[NSData alloc] initWithBase64EncodedString:certString options:0];
                         result = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)secCertificateData);
                         completion(result);
                       }] resume];
}

- (NSURL *)_certificateEndpoint
{
  NSError *error;
  NSURL *url = [FBSDKInternalUtility unversionedFacebookURLWithHostPrefix:@"m"
                                                                     path:@"/.well-known/oauth/openid/certs/"
                                                          queryParameters:@{}
                                                                    error:&error];

  return url;
}

+ (NSString *)base64FromBase64Url:(NSString *)base64Url
{
  NSString *base64 = [base64Url stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
  base64 = [base64 stringByReplacingOccurrencesOfString:@"_" withString:@"/"];

  return base64;
}

#pragma mark - Test methods

#if DEBUG

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
