/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAuthenticationTokenFactory.h"

#import <Security/Security.h>

#import <CommonCrypto/CommonCrypto.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKLoginKit/FBSDKLoginKit-Swift.h>

#import "FBSDKAuthenticationTokenHeader.h"

@interface NSURLSession (SessionProviding) <FBSDKSessionProviding>
@end

static NSString *const FBSDKBeginCertificate = @"-----BEGIN CERTIFICATE-----";
static NSString *const FBSDKEndCertificate = @"-----END CERTIFICATE-----";

typedef void (^FBSDKPublicCertCompletionBlock)(SecCertificateRef cert);
typedef void (^FBSDKPublicKeyCompletionBlock)(SecKeyRef key);
typedef void (^FBSDKVerifySignatureCompletionBlock)(BOOL success);

@interface FBSDKAuthenticationToken (FactoryInitializer)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                        graphDomain:(NSString *)graphDomain;

@end

@interface FBSDKAuthenticationTokenClaims (Internal)

+ (nullable FBSDKAuthenticationTokenClaims *)claimsFromEncodedString:(nonnull NSString *)encodedClaims
                                                               nonce:(nonnull NSString *)expectedNonce;

@end

@interface FBSDKAuthenticationTokenFactory () <NSURLSessionDelegate>

@property (nonatomic) NSString *cert;
@property (nonatomic) id<FBSDKSessionProviding> sessionProvider;

@end

@implementation FBSDKAuthenticationTokenFactory

- (instancetype)init
{
  self = [self initWithSessionProvider:[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:nil]];
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
                             nonce:(NSString *_Nonnull)nonce
                        completion:(FBSDKAuthenticationTokenBlock)completion
{
  [self createTokenFromTokenString:tokenString
                             nonce:nonce
                       graphDomain:@"facebook"
                        completion:completion];
}

- (void)createTokenFromTokenString:(NSString *_Nonnull)tokenString
                             nonce:(NSString *_Nonnull)nonce
                       graphDomain:(NSString *)graphDomain
                        completion:(FBSDKAuthenticationTokenBlock)completion
{
  if (tokenString.length == 0 || nonce.length == 0) {
    completion(nil);
    return;
  }

  NSString *signature;
  FBSDKAuthenticationTokenClaims *claims;
  FBSDKAuthenticationTokenHeader *header;

  NSArray<NSString *> *segments = [tokenString componentsSeparatedByString:@"."];
  if (segments.count != 3) {
    completion(nil);
    return;
  }

  NSString *encodedHeader = segments.firstObject;
  NSString *encodedClaims = [FBSDKTypeUtility array:segments objectAtIndex:1];
  signature = [FBSDKTypeUtility array:segments objectAtIndex:2];

  claims = [FBSDKAuthenticationTokenClaims claimsFromEncodedString:encodedClaims nonce:nonce];
  header = [FBSDKAuthenticationTokenHeader headerFromEncodedString:encodedHeader];

  if (!claims || !header) {
    completion(nil);
    return;
  }

  [self verifySignature:signature
                 header:encodedHeader
                 claims:encodedClaims
         certificateKey:header.kid
             completion:^(BOOL success) {
               if (success) {
                 FBSDKAuthenticationToken *token = [[FBSDKAuthenticationToken alloc] initWithTokenString:tokenString
                                                                                                   nonce:nonce
                                                                                             graphDomain:graphDomain];
                 completion(token);
               } else {
                 completion(nil);
               }
             }];
}

- (void)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
         certificateKey:(NSString *)certificateKey
             completion:(FBSDKVerifySignatureCompletionBlock)completion
{
#if DEBUG
#if FBTEST
  // skip signature checking for tests
  if (_skipSignatureVerification && completion) {
    completion(YES);
  }
#endif
#endif

  NSData *signatureData = [FBSDKBase64 decodeAsData:[FBSDKBase64 base64FromBase64Url:signature]];
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
                              if (key) {
                                CFRelease(key);
                              }
                            }];
}

- (void)getPublicKeyWithCertificateKey:(NSString *)certificateKey
                            completion:(FBSDKPublicKeyCompletionBlock)completion
{
  [self getCertificateWithKey:certificateKey
                   completion:^(SecCertificateRef cert) {
                     SecKeyRef publicKey = NULL;

                     if (cert) {
                       SecPolicyRef policy = SecPolicyCreateBasicX509();
                       SecTrustRef trust = NULL;

                       OSStatus status = SecTrustCreateWithCertificates(cert, policy, &trust);

                       if (status == errSecSuccess && trust) {
                         publicKey = SecTrustCopyPublicKey(trust);
                       }

                       if (trust) {
                         CFRelease(trust);
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

                         if ([response isKindOfClass:NSHTTPURLResponse.class]) {
                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                           if (httpResponse.statusCode != 200) {
                             return completion(nil);
                           }
                         }

                         SecCertificateRef result = NULL;
                         NSDictionary<NSString *, id> *certs = [FBSDKTypeUtility JSONObjectWithData:data options:0 error:nil];
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
  NSURL *url = [FBSDKUtility unversionedFacebookURLWithHostPrefix:@"m"
                                                             path:@"/.well-known/oauth/openid/certs/"
                                                  queryParameters:@{}
                                                            error:&error];

  return url;
}

#pragma mark - Test methods

#if DEBUG && FBTEST

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

#endif

@end

#endif
