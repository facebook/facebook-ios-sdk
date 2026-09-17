/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Stores the most recent inbound (app link opened into this app) and outbound (URL this app opened)
 URLs so that subsequently logged app events can be attributed to the link that produced them.

 Values are persisted so they survive the process being killed between the link being followed and
 the events it produced being logged.
 */
NS_SWIFT_NAME(_AppLinkURLCache)
@interface FBSDKAppLinkURLCache : NSObject

@property (class, readonly, strong) FBSDKAppLinkURLCache *shared;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Records @c url as the most recent inbound URL. A nil or empty URL is ignored.
- (void)cacheInboundURL:(nullable NSURL *)url;

/// Records @c url as the most recent outbound URL. A nil or empty URL is ignored.
- (void)cacheOutboundURL:(nullable NSURL *)url;

@property (nullable, nonatomic, readonly, copy) NSString *inboundURL;
@property (nullable, nonatomic, readonly, copy) NSString *outboundURL;

@end

NS_ASSUME_NONNULL_END
