/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAuthenticationTokenFactory.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBSDKVerifySignatureCompletionBlock)(BOOL success);

@interface FBSDKAuthenticationTokenFactory (Testing)

+ (void)setSkipSignatureVerification:(BOOL)value;
- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider;
- (void)setCertificate:(NSString *)certificate;
- (BOOL)verifySignature:(NSString *)signature
                 header:(NSString *)header
                 claims:(NSString *)claims
         certificateKey:(NSString *)key
             completion:(FBSDKVerifySignatureCompletionBlock)completion;
- (NSDictionary<NSString *, id> *)claims;
- (NSURL *)_certificateEndpoint;

@end

NS_ASSUME_NONNULL_END
