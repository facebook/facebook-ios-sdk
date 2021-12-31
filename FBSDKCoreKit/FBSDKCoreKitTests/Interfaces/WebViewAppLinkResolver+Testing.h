/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKWebViewAppLinkResolver.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ FBSDKURLFollowRedirectsBlock)(NSDictionary<NSString *, id> *_Nullable result, NSError *_Nullable error)
NS_SWIFT_NAME(URLFollowRedirectsBlock);

@interface FBSDKWebViewAppLinkResolver (Testing)

@property (nonatomic) id<FBSDKSessionProviding> sessionProvider;
@property (nonatomic) id<FBSDKErrorCreating> errorFactory;

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider
                           errorFactory:(id<FBSDKErrorCreating>)errorFactory;
- (void)followRedirects:(NSURL *)url handler:(FBSDKURLFollowRedirectsBlock)handler;
- (FBSDKAppLink *)appLinkFromALData:(NSDictionary<NSString *, id> *)appLinkDict
                        destination:(NSURL *)destination;

@end

NS_ASSUME_NONNULL_END
