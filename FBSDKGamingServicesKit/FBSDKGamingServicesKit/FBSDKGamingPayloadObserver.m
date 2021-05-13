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

#import "FBSDKCoreKitInternalImport.h"
#import "FBSDKGamingPayload.h"

@interface FBSDKGamingPayloadObserver () <FBSDKApplicationObserving>
@end

@implementation FBSDKGamingPayloadObserver

static FBSDKGamingPayloadObserver *shared = nil;

+ (instancetype)shared
{
  if (!shared) {
    shared = [FBSDKGamingPayloadObserver new];
  }
  return shared;
}

- (void)setDelegate:(id<FBSDKGamingPayloadDelegate>)delegate
{
  if (!delegate) {
    [[FBSDKApplicationDelegate sharedInstance] removeObserver:shared];
    shared = nil;
  }

  if (!_delegate) {
    [[FBSDKApplicationDelegate sharedInstance] addObserver:[FBSDKGamingPayloadObserver shared]];
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
  if (!sdkURL.appLinkExtras[kGamingPayload] && !sdkURL.appLinkExtras[kGamingPayloadGameRequestID]) {
    return false;
  }

  if ([_delegate respondsToSelector:@selector(updatedURLContaining:)]) {
    FBSDKGamingPayload *payload = [[FBSDKGamingPayload alloc] initWithURL:sdkURL];
    [_delegate updatedURLContaining:payload];
    return true;
  }

  return false;
}

@end
