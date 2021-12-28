/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKURL+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppLinkCreating.h"
#import "FBSDKAppLinkTargetCreating.h"
#import "FBSDKAppLinkURLKeys.h"
#import "FBSDKMeasurementEvent+Internal.h"
#import "FBSDKMeasurementEventNames.h"
#import "FBSDKSettingsProtocol.h"

NSString *const AutoAppLinkFlagKey = @"is_auto_applink";

@implementation FBSDKURL

// MARK: Dependencies

static id<FBSDKSettings> _settings;
static id<FBSDKAppLinkCreating> _appLinkFactory;
static id<FBSDKAppLinkTargetCreating> _appLinkTargetFactory;
static id<FBSDKAppLinkEventPosting> _appLinkEventPoster;

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
               appLinkFactory:(id<FBSDKAppLinkCreating>)appLinkFactory
         appLinkTargetFactory:(id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
           appLinkEventPoster:(id<FBSDKAppLinkEventPosting>)appLinkEventPoster
{
  self.settings = settings;
  self.appLinkFactory = appLinkFactory;
  self.appLinkTargetFactory = appLinkTargetFactory;
  self.appLinkEventPoster = appLinkEventPoster;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable id<FBSDKAppLinkCreating>)appLinkFactory
{
  return _appLinkFactory;
}

+ (void)setAppLinkFactory:(nullable id<FBSDKAppLinkCreating>)appLinkFactory
{
  _appLinkFactory = appLinkFactory;
}

+ (nullable id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
{
  return _appLinkTargetFactory;
}

+ (void)setAppLinkTargetFactory:(nullable id<FBSDKAppLinkTargetCreating>)appLinkTargetFactory
{
  _appLinkTargetFactory = appLinkTargetFactory;
}

+ (nullable id<FBSDKAppLinkEventPosting>)appLinkEventPoster
{
  return _appLinkEventPoster;
}

+ (void)setAppLinkEventPoster:(nullable id<FBSDKAppLinkEventPosting>)appLinkEventPoster
{
  _appLinkEventPoster = appLinkEventPoster;
}

// MARK: Initializers

- (instancetype) initWithURL:(NSURL *)url
           forOpenInboundURL:(BOOL)forOpenURLEvent
           sourceApplication:(NSString *)sourceApplication
  forRenderBackToReferrerBar:(BOOL)forRenderBackToReferrerBar
{
  if ((self = [super init])) {
    _inputURL = url;
    _targetURL = url;

    // Parse the query string parameters for the base URL
    NSDictionary<NSString *, id> *baseQuery = [FBSDKURL queryParametersForURL:url];
    _inputQueryParameters = baseQuery;
    _targetQueryParameters = baseQuery;

    // Check for applink_data
    NSString *appLinkDataString = baseQuery[FBSDKAppLinkDataParameterName];
    if (appLinkDataString) {
      // Try to parse the JSON
      NSError *error = nil;
      NSDictionary<NSString *, id> *applinkData =
      [FBSDKTypeUtility JSONObjectWithData:[appLinkDataString dataUsingEncoding:NSUTF8StringEncoding]
                                   options:0
                                     error:&error];
      if (!error && [applinkData isKindOfClass:[NSDictionary<NSString *, id> class]]) {
        // If the version is not specified, assume it is 1.
        NSString *version = applinkData[FBSDKAppLinkVersionKeyName] ?: @"1.0";
        NSString *target = applinkData[FBSDKAppLinkTargetKeyName];
        if ([version isKindOfClass:NSString.class]
            && [version isEqual:FBSDKAppLinkVersion]) {
          // There's applink data!  The target should actually be the applink target.
          _appLinkData = applinkData;
          id applinkExtras = applinkData[FBSDKAppLinkExtrasKeyName];
          if (applinkExtras && [applinkExtras isKindOfClass:[NSDictionary<NSString *, id> class]]) {
            _appLinkExtras = applinkExtras;
          }
          // Use the url derived from FBSDKAppLinkTargetKeyName if possible
          if ([target isKindOfClass:NSString.class]) {
            NSURL *appLinkTargetURL = [NSURL URLWithString:target];
            if (appLinkTargetURL) {
              _targetURL = appLinkTargetURL;
            }
          }
          _targetQueryParameters = [FBSDKURL queryParametersForURL:_targetURL];

          NSDictionary<NSString *, id> *refererAppLink = _appLinkData[FBSDKAppLinkRefererAppLink];
          NSString *refererURLString = refererAppLink[FBSDKAppLinkRefererUrl];
          NSString *refererAppName = refererAppLink[FBSDKAppLinkRefererAppName];

          if (refererURLString && refererAppName) {
            id<FBSDKAppLinkTarget> appLinkTarget = [self.class.appLinkTargetFactory createAppLinkTargetWithURL:[NSURL URLWithString:refererURLString]
                                                                                                    appStoreId:nil
                                                                                                       appName:refererAppName];
            _appLinkReferer = [self.class.appLinkFactory createAppLinkWithSourceURL:[NSURL URLWithString:refererURLString]
                                                                            targets:@[appLinkTarget]
                                                                             webURL:nil
                                                                   isBackToReferrer:YES];
          }

          // Raise Measurement Event
          NSString *const EVENT_YES_VAL = @"1";
          NSString *const EVENT_NO_VAL = @"0";
          NSMutableDictionary<NSString *, id> *logData = [NSMutableDictionary new];
          [FBSDKTypeUtility dictionary:logData setObject:version forKey:@"version"];
          if (refererURLString) {
            [FBSDKTypeUtility dictionary:logData setObject:refererURLString forKey:@"refererURL"];
          }
          if (refererAppName) {
            [FBSDKTypeUtility dictionary:logData setObject:refererAppName forKey:@"refererAppName"];
          }
          if (sourceApplication) {
            [FBSDKTypeUtility dictionary:logData setObject:sourceApplication forKey:@"sourceApplication"];
          }
          if (_targetURL.absoluteString) {
            [FBSDKTypeUtility dictionary:logData setObject:_targetURL.absoluteString forKey:@"targetURL"];
          }
          if (_inputURL.absoluteString) {
            [FBSDKTypeUtility dictionary:logData setObject:_inputURL.absoluteString forKey:@"inputURL"];
          }
          if (_inputURL.scheme) {
            [FBSDKTypeUtility dictionary:logData setObject:_inputURL.scheme forKey:@"inputURLScheme"];
          }
          [FBSDKTypeUtility dictionary:logData setObject:forRenderBackToReferrerBar ? EVENT_YES_VAL : EVENT_NO_VAL forKey:@"forRenderBackToReferrerBar"];
          [FBSDKTypeUtility dictionary:logData setObject:forOpenURLEvent ? EVENT_YES_VAL : EVENT_NO_VAL forKey:@"forOpenUrl"];
          [self.class.appLinkEventPoster postNotificationForEventName:FBSDKAppLinkParseEventName args:logData];
          if (forOpenURLEvent) {
            [self.class.appLinkEventPoster postNotificationForEventName:FBSDKAppLinkNavigateInEventName args:logData];
          }
        }
      }
    }
  }
  return self;
}

+ (instancetype)URLWithURL:(NSURL *)url
{
  return [[FBSDKURL alloc] initWithURL:url forOpenInboundURL:NO sourceApplication:nil forRenderBackToReferrerBar:NO];
}

+ (instancetype)URLWithInboundURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
  return [[FBSDKURL alloc] initWithURL:url forOpenInboundURL:YES sourceApplication:sourceApplication forRenderBackToReferrerBar:NO];
}

+ (instancetype)URLForRenderBackToReferrerBarURL:(NSURL *)url
{
  return [[FBSDKURL alloc] initWithURL:url forOpenInboundURL:NO sourceApplication:nil forRenderBackToReferrerBar:YES];
}

// MARK: Methods

- (BOOL)isAutoAppLink
{
  NSString *host = self.targetURL.host;
  NSString *scheme = self.targetURL.scheme;
  NSString *expectedHost = @"applinks";
  NSString *expectedScheme = [NSString stringWithFormat:@"fb%@", FBSDKURL.settings.appID];
  BOOL autoFlag = [self.appLinkData[AutoAppLinkFlagKey] boolValue];
  return autoFlag && [expectedHost isEqual:host] && [expectedScheme isEqual:scheme];
}

+ (NSDictionary<NSString *, id> *)queryParametersForURL:(NSURL *)url
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary dictionary];
  NSString *query = url.query;
  if ([query isEqualToString:@""]) {
    return @{};
  }
  NSArray<NSString *> *queryComponents = [query componentsSeparatedByString:@"&"];
  for (NSString *component in queryComponents) {
    NSRange equalsLocation = [component rangeOfString:@"="];
    if (equalsLocation.location == NSNotFound) {
      // There's no equals, so associate the key with NSNull
      [FBSDKTypeUtility dictionary:parameters setObject:[NSNull null] forKey:[FBSDKBasicUtility URLDecode:component]];
    } else {
      NSString *key = [FBSDKBasicUtility URLDecode:[component substringToIndex:equalsLocation.location]];
      NSString *value = [FBSDKBasicUtility URLDecode:[component substringFromIndex:equalsLocation.location + 1]];
      [FBSDKTypeUtility dictionary:parameters setObject:value forKey:key];
    }
  }
  return [NSDictionary<NSString *, id> dictionaryWithDictionary:parameters];
}

#if DEBUG && FBTEST

+ (void)reset
{
  self.settings = nil;
  self.appLinkFactory = nil;
  self.appLinkTargetFactory = nil;
  self.appLinkEventPoster = nil;
}

#endif

@end

#endif
