/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppLinkResolver.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKAppLinkResolverRequestBuilding;
@protocol FBSDKClientTokenProviding;

@interface FBSDKAppLinkResolver (Testing)

@property (nonatomic, strong) NSMutableDictionary<NSURL *, FBSDKAppLink *> *cachedFBSDKAppLinks
NS_SWIFT_NAME(cachedAppLinks);
@property (nonatomic, strong) id<FBSDKAppLinkResolverRequestBuilding> requestBuilder;
@property (nonatomic, strong) id<FBSDKClientTokenProviding> clientTokenProvider;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> accessTokenProvider;

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom;

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                            requestBuilder:(id<FBSDKAppLinkResolverRequestBuilding>)builder
                       clientTokenProvider:(id<FBSDKClientTokenProviding>)clientTokenProvider
                       accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider;

@end

NS_ASSUME_NONNULL_END
