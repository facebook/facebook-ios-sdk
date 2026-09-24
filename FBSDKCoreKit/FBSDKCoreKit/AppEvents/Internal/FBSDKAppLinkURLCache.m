/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppLinkURLCache.h"

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

static NSString *const FBSDKAppLinkInboundURLKey = @"com.facebook.sdk:inbound_url";
static NSString *const FBSDKAppLinkOutboundURLKey = @"com.facebook.sdk:outbound_url";

@interface FBSDKAppLinkURLCache ()

@property (nonatomic) id<FBSDKDataPersisting> dataStore;
@property (atomic) id<FBSDKSettings> settings;

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
    _settings = FBSDKSettings.sharedSettings;
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

// Gated here, not at the nine call sites: two are raw-IMP C functions in FBSDKAEMManager.
- (void)cacheURL:(nullable NSURL *)url forKey:(NSString *)key
{
  if (!self.settings.isMetaDataCollectionEnabled) {
    return;
  }
  NSString *urlString = url.absoluteString;
  if (urlString.length == 0) {
    return;
  }
  @synchronized(self) {
    [self.dataStore fb_setObject:urlString forKey:key];
  }
}

// The reads are gated too, so a URL cached before the developer opted out is never surfaced.
- (nullable NSString *)inboundURL
{
  if (!self.settings.isMetaDataCollectionEnabled) {
    return nil;
  }
  @synchronized(self) {
    return [self.dataStore fb_stringForKey:FBSDKAppLinkInboundURLKey];
  }
}

- (nullable NSString *)outboundURL
{
  if (!self.settings.isMetaDataCollectionEnabled) {
    return nil;
  }
  @synchronized(self) {
    return [self.dataStore fb_stringForKey:FBSDKAppLinkOutboundURLKey];
  }
}

// Intentionally ungated: this is the opt-out action itself.
- (void)clearCachedURLs
{
  @synchronized(self) {
    [self.dataStore fb_removeObjectForKey:FBSDKAppLinkInboundURLKey];
    [self.dataStore fb_removeObjectForKey:FBSDKAppLinkOutboundURLKey];
  }
}

#if DEBUG

- (void)reset
{
  [self clearCachedURLs];
  @synchronized(self) {
    self.dataStore = NSUserDefaults.standardUserDefaults;
    self.settings = FBSDKSettings.sharedSettings;
  }
}

#endif

@end
