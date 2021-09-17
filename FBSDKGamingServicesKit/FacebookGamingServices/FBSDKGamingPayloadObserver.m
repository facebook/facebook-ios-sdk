// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
