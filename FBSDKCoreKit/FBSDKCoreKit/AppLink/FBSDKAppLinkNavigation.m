/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppLinkNavigation+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppLink+Internal.h"
#import "FBSDKAppLinkEventPosting.h"
#import "FBSDKMeasurementEventNames.h"
#import "FBSDKWebViewAppLinkResolver.h"

FOUNDATION_EXPORT NSString *const FBSDKAppLinkDataParameterName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkTargetKeyName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkUserAgentKeyName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkExtrasKeyName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkVersionKeyName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkRefererAppLink;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkRefererAppName;
FOUNDATION_EXPORT NSString *const FBSDKAppLinkRefererUrl;

@interface FBSDKAppLinkNavigation ()

@property (nonatomic, copy) NSDictionary<NSString *, id> *extras;
@property (nonatomic, copy) NSDictionary<NSString *, id> *appLinkData;
@property (nonatomic, strong) FBSDKAppLink *appLink;
@property (nonnull, nonatomic) id<FBSDKSettings> settings;

@end

@implementation FBSDKAppLinkNavigation

static id<FBSDKSettings> _settings;
static id<FBSDKInternalURLOpener> _urlOpener;
static id<FBSDKAppLinkEventPosting> _appLinkEventPoster;
static id<FBSDKAppLinkResolving> _appLinkResolver;

+ (void)configureWithSettings:(nonnull id<FBSDKSettings>)settings
                    urlOpener:(nonnull id<FBSDKInternalURLOpener>)urlOpener
           appLinkEventPoster:(nonnull id<FBSDKAppLinkEventPosting>)appLinkEventPoster
              appLinkResolver:(nonnull id<FBSDKAppLinkResolving>)appLinkResolver
{
  self.settings = settings;
  self.urlOpener = urlOpener;
  self.appLinkEventPoster = appLinkEventPoster;
  self.appLinkResolver = appLinkResolver;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable id<FBSDKInternalURLOpener>)urlOpener
{
  return _urlOpener;
}

+ (void)setUrlOpener:(nullable id<FBSDKInternalURLOpener>)urlOpener
{
  _urlOpener = urlOpener;
}

+ (nullable id<FBSDKAppLinkEventPosting>)appLinkEventPoster
{
  return _appLinkEventPoster;
}

+ (void)setAppLinkEventPoster:(nullable id<FBSDKAppLinkEventPosting>)appLinkEventPoster
{
  _appLinkEventPoster = appLinkEventPoster;
}

+ (id<FBSDKAppLinkResolving>)appLinkResolver
{
  return _appLinkResolver;
}

+ (void)setAppLinkResolver:(id<FBSDKAppLinkResolving>)appLinkResolver
{
  _appLinkResolver = appLinkResolver;
}

+ (id<FBSDKAppLinkResolving>)defaultResolver
{
  return self.appLinkResolver ?: FBSDKWebViewAppLinkResolver.sharedInstance;
}

+ (void)setDefaultResolver:(id<FBSDKAppLinkResolving>)resolver
{
  self.appLinkResolver = resolver;
}

+ (instancetype)navigationWithAppLink:(FBSDKAppLink *)appLink
                               extras:(NSDictionary<NSString *, id> *)extras
                          appLinkData:(NSDictionary<NSString *, id> *)appLinkData
{
  return [self navigationWithAppLink:appLink extras:extras appLinkData:appLinkData settings:self.settings];
}

+ (instancetype)navigationWithAppLink:(FBSDKAppLink *)appLink
                               extras:(NSDictionary<NSString *, id> *)extras
                          appLinkData:(NSDictionary<NSString *, id> *)appLinkData
                             settings:(nonnull id<FBSDKSettings>)settings
{
  FBSDKAppLinkNavigation *navigation = [self new];
  navigation.appLink = appLink;
  navigation.extras = extras;
  navigation.appLinkData = appLinkData;
  navigation.settings = settings;
  return navigation;
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)callbackAppLinkDataForAppWithName:(NSString *)appName
                                                                                                    url:(NSString *)url
{
  return @{FBSDKAppLinkRefererAppLink : @{FBSDKAppLinkRefererAppName : appName, FBSDKAppLinkRefererUrl : url}};
}

- (NSString *)stringByEscapingQueryString:(NSString *)string
{
  return [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}

- (nullable NSURL *)appLinkURLWithTargetURL:(NSURL *)targetUrl error:(NSError **)error
{
  NSMutableDictionary<NSString *, id> *appLinkData =
  [NSMutableDictionary dictionaryWithDictionary:self.appLinkData ?: @{}];

  // Add applink protocol data
  if (!appLinkData[FBSDKAppLinkUserAgentKeyName]) {
    [FBSDKTypeUtility dictionary:appLinkData setObject:[NSString stringWithFormat:@"FBSDK %@", self.settings.sdkVersion] forKey:FBSDKAppLinkUserAgentKeyName];
  }
  if (!appLinkData[FBSDKAppLinkVersionKeyName]) {
    [FBSDKTypeUtility dictionary:appLinkData setObject:FBSDKAppLinkVersion forKey:FBSDKAppLinkVersionKeyName];
  }
  if (self.appLink.sourceURL.absoluteString) {
    [FBSDKTypeUtility dictionary:appLinkData setObject:self.appLink.sourceURL.absoluteString forKey:FBSDKAppLinkTargetKeyName];
  }
  [FBSDKTypeUtility dictionary:appLinkData setObject:self.extras ?: @{} forKey:FBSDKAppLinkExtrasKeyName];

  // JSON-ify the applink data
  NSError *jsonError = nil;
  NSData *jsonBlob = [FBSDKTypeUtility dataWithJSONObject:appLinkData options:0 error:&jsonError];
  if (!jsonError) {
    NSString *jsonString = [[NSString alloc] initWithData:jsonBlob encoding:NSUTF8StringEncoding];
    NSString *encoded = [self stringByEscapingQueryString:jsonString];

    NSString *endUrlString = [NSString stringWithFormat:@"%@%@%@=%@",
                              targetUrl.absoluteString,
                              targetUrl.query ? @"&" : @"?",
                              FBSDKAppLinkDataParameterName,
                              encoded];

    return [NSURL URLWithString:endUrlString];
  } else {
    if (error) {
      *error = jsonError;
    }

    // If there was an error encoding the app link data, fail hard.
    return nil;
  }
}

- (FBSDKAppLinkNavigationType)navigate:(NSError **)error
{
  return [self navigateWithUrlOpener:self.class.urlOpener
                         eventPoster:self.class.appLinkEventPoster
                               error:error];
}

- (FBSDKAppLinkNavigationType)navigateWithUrlOpener:(id<FBSDKInternalURLOpener>)urlOpener
                                        eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster
                                              error:(NSError *__autoreleasing *)error
{
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSURL *openedURL = nil;
  NSError *encodingError = nil;
  FBSDKAppLinkNavigationType retType = FBSDKAppLinkNavigationTypeFailure;

  // Find the first eligible/launchable target in the FBSDKAppLink.
  for (FBSDKAppLinkTarget *target in self.appLink.targets) {
    NSURL *appLinkAppURL = [self appLinkURLWithTargetURL:target.URL error:&encodingError];
    if (encodingError || !appLinkAppURL) {
      if (error) {
        *error = encodingError;
      }
    } else if ([urlOpener openURL:appLinkAppURL]) {
      retType = FBSDKAppLinkNavigationTypeApp;
      openedURL = appLinkAppURL;
      break;
    }
  }

  if (!openedURL && self.appLink.webURL) {
    // Fall back to opening the url in the browser if available.
    NSURL *appLinkBrowserURL = [self appLinkURLWithTargetURL:self.appLink.webURL error:&encodingError];
    if (encodingError || !appLinkBrowserURL) {
      // If there was an error encoding the app link data, fail hard.
      if (error) {
        *error = encodingError;
      }
    } else if ([urlOpener openURL:appLinkBrowserURL]) {
      // This was a browser navigation.
      retType = FBSDKAppLinkNavigationTypeBrowser;
      openedURL = appLinkBrowserURL;
    }
  }
  #pragma clang diagnostic pop

  [self postAppLinkNavigateEventNotificationWithTargetURL:openedURL
                                                    error:error ? *error : nil
                                                     type:retType
                                              eventPoster:eventPoster];
  return retType;
}

- (void)postAppLinkNavigateEventNotificationWithTargetURL:(NSURL *)outputURL
                                                    error:(NSError *)error
                                                     type:(FBSDKAppLinkNavigationType)type
{
  [self postAppLinkNavigateEventNotificationWithTargetURL:outputURL
                                                    error:error
                                                     type:type
                                              eventPoster:self.class.appLinkEventPoster];
}

- (void)postAppLinkNavigateEventNotificationWithTargetURL:(NSURL *)outputURL
                                                    error:(NSError *)error
                                                     type:(FBSDKAppLinkNavigationType)type
                                              eventPoster:(id<FBSDKAppLinkEventPosting>)eventPoster
{
  NSString *const EVENT_YES_VAL = @"1";
  NSString *const EVENT_NO_VAL = @"0";
  NSMutableDictionary<NSString *, id> *logData =
  [NSMutableDictionary new];

  NSString *outputURLScheme = outputURL.scheme;
  NSString *outputURLString = outputURL.absoluteString;
  if (outputURLScheme) {
    [FBSDKTypeUtility dictionary:logData setObject:outputURLScheme forKey:@"outputURLScheme"];
  }
  if (outputURLString) {
    [FBSDKTypeUtility dictionary:logData setObject:outputURLString forKey:@"outputURL"];
  }

  NSString *sourceURLString = self.appLink.sourceURL.absoluteString;
  NSString *sourceURLHost = self.appLink.sourceURL.host;
  NSString *sourceURLScheme = self.appLink.sourceURL.scheme;
  if (sourceURLString) {
    [FBSDKTypeUtility dictionary:logData setObject:sourceURLString forKey:@"sourceURL"];
  }
  if (sourceURLHost) {
    [FBSDKTypeUtility dictionary:logData setObject:sourceURLHost forKey:@"sourceHost"];
  }
  if (sourceURLScheme) {
    [FBSDKTypeUtility dictionary:logData setObject:sourceURLScheme forKey:@"sourceScheme"];
  }
  if (error.localizedDescription) {
    [FBSDKTypeUtility dictionary:logData setObject:error.localizedDescription forKey:@"error"];
  }
  NSString *success = nil; // no
  NSString *linkType = nil; // unknown;
  switch (type) {
    case FBSDKAppLinkNavigationTypeFailure:
      success = EVENT_NO_VAL;
      linkType = @"fail";
      break;
    case FBSDKAppLinkNavigationTypeBrowser:
      success = EVENT_YES_VAL;
      linkType = @"web";
      break;
    case FBSDKAppLinkNavigationTypeApp:
      success = EVENT_YES_VAL;
      linkType = @"app";
      break;
    default:
      break;
  }
  if (success) {
    [FBSDKTypeUtility dictionary:logData setObject:success forKey:@"success"];
  }
  if (linkType) {
    [FBSDKTypeUtility dictionary:logData setObject:linkType forKey:@"type"];
  }

  if (self.appLink.backToReferrer) {
    [eventPoster postNotificationForEventName:FBSDKAppLinkNavigateBackToReferrerEventName args:logData];
  } else {
    [eventPoster postNotificationForEventName:FBSDKAppLinkNavigateOutEventName args:logData];
  }
}

+ (void)resolveAppLink:(NSURL *)destination
              resolver:(id<FBSDKAppLinkResolving>)resolver
               handler:(FBSDKAppLinkBlock)handler
{
  [resolver appLinkFromURL:destination handler:handler];
}

+ (void)resolveAppLink:(NSURL *)destination handler:(FBSDKAppLinkBlock)handler
{
  if (self.appLinkResolver) {
    [self resolveAppLink:destination resolver:self.appLinkResolver handler:handler];
  }
}

+ (void)navigateToURL:(NSURL *)destination handler:(FBSDKAppLinkNavigationBlock)handler
{
  if (self.appLinkResolver) {
    [self navigateToURL:destination resolver:self.appLinkResolver handler:handler];
  }
}

+ (void)navigateToURL:(NSURL *)destination
             resolver:(id<FBSDKAppLinkResolving>)resolver
              handler:(FBSDKAppLinkNavigationBlock)handler
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self resolveAppLink:destination
                resolver:resolver
                 handler:^(FBSDKAppLink *_Nullable appLink, NSError *_Nullable error) {
                   if (error) {
                     handler(FBSDKAppLinkNavigationTypeFailure, error);
                     return;
                   }

                   NSError *navigateError = nil;
                   FBSDKAppLinkNavigationType result = [self navigateToAppLink:appLink error:&navigateError];
                   handler(result, navigateError);
                 }];
  });
}

+ (FBSDKAppLinkNavigationType)navigateToAppLink:(FBSDKAppLink *)link error:(NSError **)error
{
  return [[FBSDKAppLinkNavigation navigationWithAppLink:link
                                                 extras:@{}
                                            appLinkData:@{}
                                               settings:self.settings] navigate:error];
}

+ (FBSDKAppLinkNavigationType)navigationTypeForLink:(FBSDKAppLink *)link
{
  return [[self navigationWithAppLink:link extras:@{} appLinkData:@{} settings:self.settings] navigationType];
}

- (FBSDKAppLinkNavigationType)navigationType
{
  return [self navigationTypeForTargets:self.appLink.targets urlOpener:self.class.urlOpener];
}

- (FBSDKAppLinkNavigationType)navigationTypeForTargets:(nonnull NSArray<id<FBSDKAppLinkTarget>> *)targets
                                             urlOpener:(nullable id<FBSDKInternalURLOpener>)urlOpener
{
  FBSDKAppLinkTarget *eligibleTarget = nil;
  for (FBSDKAppLinkTarget *target in self.appLink.targets) {
    if ([urlOpener canOpenURL:target.URL]) {
      eligibleTarget = target;
      break;
    }
  }

  if (eligibleTarget != nil) {
    NSURL *appLinkURL = [self appLinkURLWithTargetURL:eligibleTarget.URL error:nil];
    if (appLinkURL != nil) {
      return FBSDKAppLinkNavigationTypeApp;
    } else {
      return FBSDKAppLinkNavigationTypeFailure;
    }
  }

  if (self.appLink.webURL != nil) {
    NSURL *appLinkURL = [self appLinkURLWithTargetURL:eligibleTarget.URL error:nil];
    if (appLinkURL != nil) {
      return FBSDKAppLinkNavigationTypeBrowser;
    } else {
      return FBSDKAppLinkNavigationTypeFailure;
    }
  }

  return FBSDKAppLinkNavigationTypeFailure;
}

#if DEBUG && FBTEST

+ (void)reset
{
  self.settings = nil;
  self.urlOpener = nil;
  self.appLinkEventPoster = nil;
  self.appLinkResolver = nil;
}

#endif

@end

#endif
