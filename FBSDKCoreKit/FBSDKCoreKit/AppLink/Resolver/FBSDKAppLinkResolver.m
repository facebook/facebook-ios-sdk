/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkResolver.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAccessTokenProtocols.h"
#import "FBSDKAppLink.h"
#import "FBSDKAppLinkResolverRequestBuilder+Internal.h"
#import "FBSDKAppLinkResolverRequestBuilding.h"
#import "FBSDKClientTokenProviding.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings+Internal.h"

static NSString *const kURLKey = @"url";
static NSString *const kIOSAppStoreIdKey = @"app_store_id";
static NSString *const kIOSAppNameKey = @"app_name";
static NSString *const kWebKey = @"web";
static NSString *const kIOSKey = @"ios";
static NSString *const kIPhoneKey = @"iphone";
static NSString *const kIPadKey = @"ipad";
static NSString *const kShouldFallbackKey = @"should_fallback";
static NSString *const kAppLinksKey = @"app_links";

@interface FBSDKAppLinkResolver ()

@property (nonatomic, strong) NSMutableDictionary<NSURL *, FBSDKAppLink *> *cachedFBSDKAppLinks;
@property (nonatomic, assign) UIUserInterfaceIdiom userInterfaceIdiom;
@property (nonatomic, strong) id<FBSDKAppLinkResolverRequestBuilding> requestBuilder;
@property (nonatomic, strong) id<FBSDKClientTokenProviding> clientTokenProvider;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> accessTokenProvider;

@end

@implementation FBSDKAppLinkResolver

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
{
  return [self initWithUserInterfaceIdiom:userInterfaceIdiom
                           requestBuilder:[FBSDKAppLinkResolverRequestBuilder new]
                      clientTokenProvider:FBSDKSettings.sharedSettings
                      accessTokenProvider:FBSDKAccessToken.class];
}

#pragma clang diagnostic pop

- (instancetype)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                            requestBuilder:(id<FBSDKAppLinkResolverRequestBuilding>)builder
                       clientTokenProvider:(id<FBSDKClientTokenProviding>)clientTokenProvider
                       accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  if ((self = [super init])) {
    _cachedFBSDKAppLinks = [NSMutableDictionary dictionary];
    _userInterfaceIdiom = userInterfaceIdiom;
    _requestBuilder = builder;
    _clientTokenProvider = clientTokenProvider;
    _accessTokenProvider = accessTokenProvider;
  }
  return self;
}

- (void)appLinkFromURL:(NSURL *)url handler:(FBSDKAppLinkBlock)handler
{
  [self appLinksFromURLs:@[url] handler:^(NSDictionary<NSURL *, FBSDKAppLink *> *urls, NSError *_Nullable error) {
    handler(urls[url], error);
  }];
}

- (void)appLinksFromURLs:(NSArray<NSURL *> *)urls handler:(FBSDKAppLinksBlock)handler
{
  if (!self.clientTokenProvider.clientToken && ![self.accessTokenProvider currentAccessToken]) {
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:@"A user access token or clientToken is required to use FBAppLinkResolver"];
  }

  NSMutableDictionary<NSURL *, FBSDKAppLink *> *appLinks = [NSMutableDictionary dictionary];
  NSMutableArray<NSURL *> *toFind = [NSMutableArray array];

  @synchronized(self.cachedFBSDKAppLinks) {
    for (NSURL *url in urls) {
      if (self.cachedFBSDKAppLinks[url]) {
        [FBSDKTypeUtility dictionary:appLinks setObject:self.cachedFBSDKAppLinks[url] forKey:url];
      } else {
        [FBSDKTypeUtility array:toFind addObject:url];
      }
    }
  }
  if (toFind.count == 0) {
    // All of the URLs have already been found.
    handler(appLinks, nil);
    return;
  }

  id<FBSDKGraphRequest> request = [self.requestBuilder requestForURLs:urls];

  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (error) {
      handler(@{}, error);
      return;
    }

    for (NSURL *url in toFind) {
      FBSDKAppLink *link = [self buildAppLinkForURL:url inResults:result];

      @synchronized(self.cachedFBSDKAppLinks) {
        [FBSDKTypeUtility dictionary:self.cachedFBSDKAppLinks setObject:link forKey:url];
      }

      [FBSDKTypeUtility dictionary:appLinks setObject:link forKey:url];
    }
    handler(appLinks, nil);
  }];
}

- (FBSDKAppLink *)buildAppLinkForURL:(NSURL *)url inResults:(id)result
{
  NSString *idiomSpecificField = [self.requestBuilder getIdiomSpecificField];

  id nestedObject = result[url.absoluteString][kAppLinksKey];
  NSMutableArray *rawTargets = [NSMutableArray array];
  if (idiomSpecificField) {
    [rawTargets addObjectsFromArray:nestedObject[idiomSpecificField]];
  }
  [rawTargets addObjectsFromArray:nestedObject[kIOSKey]];

  NSMutableArray<FBSDKAppLinkTarget *> *targets = [NSMutableArray arrayWithCapacity:rawTargets.count];
  for (id rawTarget in rawTargets) {
    [FBSDKTypeUtility array:targets addObject:[FBSDKAppLinkTarget appLinkTargetWithURL:[NSURL URLWithString:rawTarget[kURLKey]]
                                                                            appStoreId:rawTarget[kIOSAppStoreIdKey]
                                                                               appName:rawTarget[kIOSAppNameKey]]];
  }

  id webTarget = nestedObject[kWebKey];
  NSString *webFallbackString = webTarget[kURLKey];
  NSURL *fallbackUrl = webFallbackString ? [NSURL URLWithString:webFallbackString] : url;

  NSNumber *shouldFallback = webTarget[kShouldFallbackKey];
  if (shouldFallback != nil && !shouldFallback.boolValue) {
    fallbackUrl = nil;
  }

  return [FBSDKAppLink appLinkWithSourceURL:url
                                    targets:targets
                                     webURL:fallbackUrl];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
+ (instancetype)resolver
{
  return [[self alloc] initWithUserInterfaceIdiom:UIDevice.currentDevice.userInterfaceIdiom];
}

#pragma clang diagnostic pop

@end

#endif
