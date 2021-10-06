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

#if !TARGET_OS_TV

#import "FBSDKAppLinkUtility+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAdvertiserIDProviding.h"
#import "FBSDKAppEventDropDetermining.h"
#import "FBSDKAppEventParametersExtracting.h"
#import "FBSDKAppEventsConfigurationProviding.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestHTTPMethod.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKURL.h"

static NSString *const FBSDKLastDeferredAppLink = @"com.facebook.sdk:lastDeferredAppLink%@";
static NSString *const FBSDKDeferredAppLinkEvent = @"DEFERRED_APP_LINK";

@interface FBSDKAppLinkUtility ()

@property (class, nonatomic) BOOL isConfigured;

@end

@implementation FBSDKAppLinkUtility

static id<FBSDKGraphRequestFactory> _graphRequestFactory;
static id<FBSDKInfoDictionaryProviding> _infoDictionaryProvider;
static id<FBSDKSettings> _settings;
static id<FBSDKAppEventsConfigurationProviding> _appEventsConfigurationProvider;
static id<FBSDKAdvertiserIDProviding> _advertiserIDProvider;
static id<FBSDKAppEventDropDetermining> _appEventsDropDeterminer;
static id<FBSDKAppEventParametersExtracting> _appEventParametersExtractor;
static BOOL _isConfigured;

+ (void)configureWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                  infoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                settings:(id<FBSDKSettings>)settings
          appEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                    advertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
                 appEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
             appEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
{
  if (self == FBSDKAppLinkUtility.class) {
    self.graphRequestFactory = graphRequestFactory;
    self.infoDictionaryProvider = infoDictionaryProvider;
    self.settings = settings;
    self.appEventsConfigurationProvider = appEventsConfigurationProvider;
    self.advertiserIDProvider = advertiserIDProvider;
    self.appEventsDropDeterminer = appEventsDropDeterminer;
    self.appEventParametersExtractor = appEventParametersExtractor;
    self.isConfigured = YES;
  }
}

// MARK: - Properties

+ (id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  return _graphRequestFactory;
}

+ (void)setGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  _graphRequestFactory = graphRequestFactory;
}

+ (id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  return _infoDictionaryProvider;
}

+ (void)setInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
{
  _infoDictionaryProvider = infoDictionaryProvider;
}

+ (id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
{
  return _appEventsConfigurationProvider;
}

+ (void)setAppEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
{
  _appEventsConfigurationProvider = appEventsConfigurationProvider;
}

+ (id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
{
  return _advertiserIDProvider;
}

+ (void)setAdvertiserIDProvider:(id<FBSDKAdvertiserIDProviding>)advertiserIDProvider
{
  _advertiserIDProvider = advertiserIDProvider;
}

+ (id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
{
  return _appEventsDropDeterminer;
}

+ (void)setAppEventsDropDeterminer:(id<FBSDKAppEventDropDetermining>)appEventsDropDeterminer
{
  _appEventsDropDeterminer = appEventsDropDeterminer;
}

+ (id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
{
  return _appEventParametersExtractor;
}

+ (void)setAppEventParametersExtractor:(id<FBSDKAppEventParametersExtracting>)appEventParametersExtractor
{
  _appEventParametersExtractor = appEventParametersExtractor;
}

+ (BOOL)isConfigured
{
  return _isConfigured;
}

+ (void)setIsConfigured:(BOOL)isConfigured
{
  _isConfigured = isConfigured;
}

// MARK: - Public Methods

+ (void)fetchDeferredAppLink:(nullable FBSDKURLBlock)handler
{
  [self validateConfiguration];
  NSAssert(NSThread.isMainThread, @"FBSDKAppLink fetchDeferredAppLink: must be invoked from main thread.");

  [self.appEventsConfigurationProvider loadAppEventsConfigurationWithBlock:^{
    if ([self.appEventsDropDeterminer shouldDropAppEvents]) {
      if (handler) {
        NSError *error = [[NSError alloc] initWithDomain:@"AdvertiserTrackingEnabled must be enabled" code:-1 userInfo:nil];
        handler(nil, error);
      }
      return;
    }

    if (@available(iOS 14.5, *)) {
      NSString *defaultAdvertiserID = @"00000000-0000-0000-0000-000000000000";
      BOOL isAdvertiserIDMissingOrDefault = !self.advertiserIDProvider.advertiserID
      || [self.advertiserIDProvider.advertiserID isEqualToString:defaultAdvertiserID];

      if (handler && isAdvertiserIDMissingOrDefault) {
        NSError *error = [[NSError alloc] initWithDomain:@"ATTrackingManager.AuthorizationStatus must be `authorized` for deferred deep linking to work. Read more at: https://developer.apple.com/documentation/apptrackingtransparency" code:-1 userInfo:nil];
        handler(nil, error);
        return;
      }
    }

    // Deferred app links are only currently used for engagement ads, thus we consider the app to be an advertising one.
    // If this is considered for organic, non-ads scenarios, we'll need to retrieve the FBAppEventsUtility.shouldAccessAdvertisingID
    // before we make this call.
    NSMutableDictionary<NSString *, id> *deferredAppLinkParameters =
    [self.appEventParametersExtractor activityParametersDictionaryForEvent:FBSDKDeferredAppLinkEvent
                                                 shouldAccessAdvertisingID:YES];
    id<FBSDKGraphRequest> deferredAppLinkRequest = [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/activities", self.settings.appID, nil]
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

+ (nullable NSString *)appInvitePromotionCodeFromURL:(NSURL *)url
{
  [self validateConfiguration];
  FBSDKURL *parsedUrl = [FBSDKURL URLWithURL:url];
  NSDictionary<NSString *, id> *extras = parsedUrl.appLinkExtras;
  if (extras) {
    NSString *deeplinkContextString = extras[@"deeplink_context"];

    // Parse deeplinkContext and extract promo code
    if (deeplinkContextString.length > 0) {
      NSError *error = nil;
      NSDictionary<id, id> *deeplinkContextData = [FBSDKBasicUtility objectForJSONString:deeplinkContextString error:&error];
      if (!error && [deeplinkContextData isKindOfClass:[NSDictionary<NSString *, id> class]]) {
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
  for (NSDictionary<NSString *, id> *urlType in [self.infoDictionaryProvider objectForInfoDictionaryKey:@"CFBundleURLTypes"]) {
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
    "Learn more: https://developers.facebook.com/docs/ios/getting-started"
    "If no `UIApplication` is available you can use `FBSDKApplicationDelegate`'s `initializeSDK` method.";
    @throw [NSException exceptionWithName:@"InvalidOperationException" reason:reason userInfo:nil];
  }
#endif
}

#if DEBUG && FBTEST

+ (void)reset
{
  _isConfigured = NO;
  _graphRequestFactory = nil;
  _infoDictionaryProvider = nil;
  _settings = nil;
  _appEventsConfigurationProvider = nil;
  _advertiserIDProvider = nil;
  _appEventsDropDeterminer = nil;
  _appEventParametersExtractor = nil;
}

#endif

@end

#endif
