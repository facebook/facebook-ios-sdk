/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingPayloadObserver.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKGamingContext.h"
#import "FBSDKGamingPayload.h"

@interface FBSDKGamingPayloadObserver () <FBSDKApplicationObserving>
@end

@implementation FBSDKGamingPayloadObserver

static FBSDKGamingPayloadObserver *sharedInstance = nil;

+ (instancetype)shared
{
  if (!sharedInstance) {
    sharedInstance = [FBSDKGamingPayloadObserver new];
  }
  return sharedInstance;
}

- (instancetype)initWithDelegate:(id<FBSDKGamingPayloadDelegate>)delegate
{
  if ((self = [super init])) {
    _delegate = delegate;
    [FBSDKApplicationDelegate.sharedInstance addObserver:self];
  }

  return self;
}

- (void)setDelegate:(id<FBSDKGamingPayloadDelegate>)delegate
{
  if (sharedInstance) {
    if (!delegate) {
      [FBSDKApplicationDelegate.sharedInstance removeObserver:sharedInstance];
      sharedInstance = nil;
    }

    if (!_delegate) {
      [FBSDKApplicationDelegate.sharedInstance addObserver:sharedInstance];
    }
  }

  _delegate = delegate;
}

#pragma mark -- FBSDKApplicationObserving

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
  FBSDKURL *sdkURL = [FBSDKURL URLWithURL:url];
  BOOL urlContainsGamingPayload = sdkURL.appLinkExtras[kGamingPayload] != nil;
  BOOL urlContainsGameRequestID = sdkURL.appLinkExtras[kGamingPayloadGameRequestID] != nil;
  BOOL urlContainsGameContextTokenID = sdkURL.appLinkExtras[kGamingPayloadContextTokenID] != nil;

  if (!urlContainsGamingPayload || (urlContainsGameContextTokenID && urlContainsGameRequestID)) {
    return false;
  }

  FBSDKGamingPayload *payload = [[FBSDKGamingPayload alloc] initWithURL:sdkURL];
  if (urlContainsGameRequestID && [(NSObject *)self.delegate respondsToSelector:@selector(parsedGameRequestURLContaining:gameRequestID:)]) {
    [_delegate parsedGameRequestURLContaining:payload gameRequestID:sdkURL.appLinkExtras[kGamingPayloadGameRequestID]];
    return true;
  }

  if (urlContainsGameContextTokenID
      && [(NSObject *)self.delegate respondsToSelector:@selector(parsedGamingContextURLContaining:)]) {
    [FBSDKGamingContext createContextWithIdentifier:sdkURL.appLinkExtras[kGamingPayloadContextTokenID] size:0];
    [_delegate parsedGamingContextURLContaining:payload];
    return true;
  }
  return false;
}

@end
