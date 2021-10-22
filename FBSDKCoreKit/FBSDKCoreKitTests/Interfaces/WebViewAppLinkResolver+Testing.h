/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKWebViewAppLinkResolver.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^FBSDKURLFollowRedirectsBlock)(NSDictionary<NSString *, id> * _Nullable result, NSError * _Nullable error)
NS_SWIFT_NAME(URLFollowRedirectsBlock);

@interface FBSDKWebViewAppLinkResolver (Testing)

@property (nonatomic, strong) id<FBSDKSessionProviding> sessionProvider;

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider;
- (void)followRedirects:(NSURL *)url handler:(FBSDKURLFollowRedirectsBlock)handler;
- (FBSDKAppLink *)appLinkFromALData:(NSDictionary<NSString *, id> *)appLinkDict
                        destination:(NSURL *)destination;

@end

NS_ASSUME_NONNULL_END
