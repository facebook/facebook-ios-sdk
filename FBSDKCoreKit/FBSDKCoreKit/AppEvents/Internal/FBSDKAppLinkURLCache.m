/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppLinkURLCache.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

static NSString *const FBSDKAppLinkInboundURLKey = @"com.facebook.sdk:inbound_url";
static NSString *const FBSDKAppLinkOutboundURLKey = @"com.facebook.sdk:outbound_url";

@interface FBSDKAppLinkURLCache ()

@property (nonatomic) id<FBSDKDataPersisting> dataStore;

@end

@implementation FBSDKAppLinkURLCache

+ (instancetype)shared
{
  static FBSDKAppLinkURLCache *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] initPrivate];
  });
  return shared;
}

- (instancetype)initPrivate
{
  if ((self = [super init])) {
    _dataStore = NSUserDefaults.standardUserDefaults;
  }
  return self;
}

- (void)cacheInboundURL:(NSURL *)url
{
  [self cacheURL:url forKey:FBSDKAppLinkInboundURLKey];
}

- (void)cacheOutboundURL:(NSURL *)url
{
  [self cacheURL:url forKey:FBSDKAppLinkOutboundURLKey];
}

- (void)cacheURL:(nullable NSURL *)url forKey:(NSString *)key
{
  NSString *urlString = url.absoluteString;
  if (urlString.length == 0) {
    return;
  }
  @synchronized(self) {
    [self.dataStore fb_setObject:urlString forKey:key];
  }
}

- (nullable NSString *)inboundURL
{
  @synchronized(self) {
    return [self.dataStore fb_stringForKey:FBSDKAppLinkInboundURLKey];
  }
}

- (nullable NSString *)outboundURL
{
  @synchronized(self) {
    return [self.dataStore fb_stringForKey:FBSDKAppLinkOutboundURLKey];
  }
}

#if DEBUG

- (void)reset
{
  @synchronized(self) {
    [self.dataStore fb_removeObjectForKey:FBSDKAppLinkInboundURLKey];
    [self.dataStore fb_removeObjectForKey:FBSDKAppLinkOutboundURLKey];
    self.dataStore = NSUserDefaults.standardUserDefaults;
  }
}

#endif

@end
