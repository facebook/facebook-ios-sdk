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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKAppLinkUtility.h"

 #import "FBSDKAppEventsConfigurationManager.h"
 #import "FBSDKAppEventsUtility.h"
 #import "FBSDKCoreKit+Internal.h"
 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKGraphRequestProviding.h"
 #import "FBSDKSettings.h"
 #import "FBSDKURL.h"

static NSString *const FBSDKLastDeferredAppLink = @"com.facebook.sdk:lastDeferredAppLink%@";
static NSString *const FBSDKDeferredAppLinkEvent = @"DEFERRED_APP_LINK";
static id<FBSDKGraphRequestProviding> _requestProvider;
static id<FBSDKInfoDictionaryProviding> _infoDictionaryProvider;
static BOOL _isConfigured;

@implementation FBSDKAppLinkUtility
{}

+ (void)configureWithRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
              infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  if (self == [FBSDKAppLinkUtility class]) {
    _requestProvider = requestProvider;
    _infoDictionaryProvider = infoDictionaryProvider;
    _isConfigured = YES;
  }
}

+ (void)fetchDeferredAppLink:(FBSDKURLBlock)handler
{
  [self validateConfiguration];
  NSAssert([NSThread isMainThread], @"FBSDKAppLink fetchDeferredAppLink: must be invoked from main thread.");

  [FBSDKAppEventsConfigurationManager loadAppEventsConfigurationWithBlock:^{
    if ([FBSDKAppEventsUtility shouldDropAppEvent]) {
      if (handler) {
        NSError *error = [[NSError alloc] initWithDomain:@"AdvertiserTrackingEnabled must be enabled" code:-1 userInfo:nil];
        handler(nil, error);
      }
      return;
    }

    NSString *appID = [FBSDKSettings appID];

    // Deferred app links are only currently used for engagement ads, thus we consider the app to be an advertising one.
    // If this is considered for organic, non-ads scenarios, we'll need to retrieve the FBAppEventsUtility.shouldAccessAdvertisingID
    // before we make this call.
    NSMutableDictionary *deferredAppLinkParameters =
    [FBSDKAppEventsUtility activityParametersDictionaryForEvent:FBSDKDeferredAppLinkEvent
                                      shouldAccessAdvertisingID:YES];
    id<FBSDKGraphRequest> deferredAppLinkRequest = [_requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/activities", appID, nil]
                                                                                          parameters:deferredAppLinkParameters
                                                                                         tokenString:nil
                                                                                             version:nil
                                                                                          HTTPMethod:FBSDKHTTPMethodPOST];
    [deferredAppLinkRequest startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection,
                                                  id result,
                                                  NSError *error) {
                                                    NSURL *applinkURL = nil;
                                                    if (!error) {
                                                      NSString *appLinkString = result[@"applink_url"];
                                                      if (appLinkString) {
                                                        applinkURL = [NSURL URLWithString:appLinkString];

                                                        NSString *createTimeUtc = result[@"click_time"];
                                                        if (createTimeUtc) {
                                                          // append/translate the create_time_utc so it can be used by clients
                                                          NSString *modifiedURLString = [applinkURL.absoluteString
                                                                                         stringByAppendingFormat:@"%@fb_click_time_utc=%@",
                                                                                         (applinkURL.query) ? @"&" : @"?",
                                                                                         createTimeUtc];
                                                          applinkURL = [NSURL URLWithString:modifiedURLString];
                                                        }
                                                      }
                                                    }

                                                    if (handler) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        handler(applinkURL, error);
                                                      });
                                                    }
                                                  }];
  }];
}

+ (NSString *)appInvitePromotionCodeFromURL:(NSURL *)url
{
  [self validateConfiguration];
  FBSDKURL *parsedUrl = [FBSDKURL URLWithURL:url];
  NSDictionary *extras = parsedUrl.appLinkExtras;
  if (extras) {
    NSString *deeplinkContextString = extras[@"deeplink_context"];

    // Parse deeplinkContext and extract promo code
    if (deeplinkContextString.length > 0) {
      NSError *error = nil;
      NSDictionary<id, id> *deeplinkContextData = [FBSDKBasicUtility objectForJSONString:deeplinkContextString error:&error];
      if (!error && [deeplinkContextData isKindOfClass:[NSDictionary class]]) {
        return deeplinkContextData[@"promo_code"];
      }
    }
  }

  return nil;
}

+ (BOOL)isMatchURLScheme:(NSString *)scheme
{
  if (!scheme) {
    return NO;
  }
  [self validateConfiguration];
  for (NSDictionary *urlType in [_infoDictionaryProvider objectForInfoDictionaryKey:@"CFBundleURLTypes"]) {
    for (NSString *urlScheme in urlType[@"CFBundleURLSchemes"]) {
      if ([urlScheme caseInsensitiveCompare:scheme] == NSOrderedSame) {
        return YES;
      }
    }
  }
  return NO;
}

// MARK: Configuration Validation

+ (void)validateConfiguration
{
#if DEBUG
  if (!_isConfigured) {
    static NSString *const reason = @"As of v9.0, you must initialize the SDK prior to calling any methods or setting any properties. "
    "You can do this by calling `FBSDKApplicationDelegate`'s `application:didFinishLaunchingWithOptions:` method."
    "Learn more: https://developers.facebook.com/docs/ios/getting-started";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
#endif
}

 #if DEBUG
  #if FBSDKTEST

+ (void)reset
{
  _isConfigured = NO;
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return _requestProvider;
}

+ (id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  return _infoDictionaryProvider;
}

  #endif
 #endif

@end

#endif
