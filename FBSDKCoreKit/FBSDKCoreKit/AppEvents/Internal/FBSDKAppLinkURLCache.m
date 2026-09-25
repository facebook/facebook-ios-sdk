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
@property (atomic) id<FBSDKFeatureChecking> featureChecker;

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
    _featureChecker = FBSDKFeatureManager.shared;
  }
  return self;
}

// Both controls mean "do not collect", so both gate the write as well as the read: a URL that
// is never captured cannot be retained on the device, which is a stronger position than
// capturing it and declining to send it. Checked here rather than at the nine call sites
// because two of them are raw-IMP C functions in FBSDKAEMManager, which have nowhere to hold a
// dependency — and reaching those AEM writers is the point, since they install under the AEM
// feature and the MetadataCollection GateKeeper could not otherwise touch them.
//
// The cost is that a deep link arriving before the GateKeeper fetch lands is dropped and cannot
// be recovered. That is accepted: `inbound_url` is a supplementary event parameter, not the
// attribution mechanism, and AEM's own `handle:` and `saveCampaignIDs:` paths are untouched.
- (BOOL)isCollectionPermitted
{
  return self.settings.isMetaDataCollectionEnabled
  && [self.featureChecker isEnabled:FBSDKFeatureMetadataCollection];
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
  if (!self.isCollectionPermitted) {
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

// Gated as well as the write, so a URL cached before either control was turned off is never
// surfaced. The write gate alone is not enough: both values persist across launches.
- (nullable NSString *)inboundURL
{
  if (!self.isCollectionPermitted) {
    return nil;
  }
  @synchronized(self) {
    return [self.dataStore fb_stringForKey:FBSDKAppLinkInboundURLKey];
  }
}

- (nullable NSString *)outboundURL
{
  if (!self.isCollectionPermitted) {
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
    self.featureChecker = FBSDKFeatureManager.shared;
  }
}

#endif

@end
