/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsUtility.h"

#import <AdSupport/AdSupport.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>

#import "FBSDKAppEventName+Internal.h"
#import "FBSDKAppEventsConfiguration.h"
#import "FBSDKAppEventsFlushReason.h"
#import "FBSDKDynamicFrameworkLoader.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings+Internal.h"

#define FBSDK_APPEVENTSUTILITY_ANONYMOUSIDFILENAME @"com-facebook-sdk-PersistedAnonymousID.json"
#define FBSDK_APPEVENTSUTILITY_ANONYMOUSID_KEY @"anon_id"
#define FBSDK_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH 40

@interface FBSDKAppEventsUtility ()

@property (nullable, nonatomic) ASIdentifierManager *cachedAdvertiserIdentifierManager;

@end

@implementation FBSDKAppEventsUtility

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal is to move from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
static FBSDKAppEventsUtility *_shared;

+ (instancetype)shared
{
  @synchronized(self) {
    if (!_shared) {
      _shared = [self new];
    }
  }

  return _shared;
}

+ (void)setShared:(FBSDKAppEventsUtility *)shared
{
  _shared = shared;
}

- (void)configureWithAppEventsConfigurationProvider:(id<FBSDKAppEventsConfigurationProviding>)appEventsConfigurationProvider
                          deviceInformationProvider:(id<FBSDKDeviceInformationProviding>)deviceInformationProvider
                                           settings:(id<FBSDKSettings>)settings
                                    internalUtility:(id<FBSDKInternalUtility>)internalUtility
                                       errorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  self.appEventsConfigurationProvider = appEventsConfigurationProvider;
  self.deviceInformationProvider = deviceInformationProvider;
  self.settings = settings;
  self.internalUtility = internalUtility;
  self.errorFactory = errorFactory;
}

- (NSMutableDictionary<NSString *, NSString *> *)activityParametersDictionaryForEvent:(NSString *)eventCategory
                                                            shouldAccessAdvertisingID:(BOOL)shouldAccessAdvertisingID
                                                                               userID:(nullable NSString *)userID
                                                                             userData:(nullable NSString *)userData
{
  NSMutableDictionary<NSString *, NSString *> *parameters = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:parameters setObject:eventCategory forKey:@"event"];

  if (shouldAccessAdvertisingID) {
    [FBSDKTypeUtility dictionary:parameters setObject:self.advertiserID forKey:@"advertiser_id"];
  }

  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKBasicUtility anonymousID] forKey:FBSDK_APPEVENTSUTILITY_ANONYMOUSID_KEY];

  FBSDKAdvertisingTrackingStatus advertisingTrackingStatus = self.settings.advertisingTrackingStatus;
  if (advertisingTrackingStatus != FBSDKAdvertisingTrackingUnspecified) {
    [FBSDKTypeUtility dictionary:parameters setObject:@(self.settings.isAdvertiserTrackingEnabled).stringValue forKey:@"advertiser_tracking_enabled"];
  }

  if (userData) {
    [FBSDKTypeUtility dictionary:parameters setObject:userData forKey:@"ud"];
  } else {
    // Preserving existing behavior which was to pass a hashed version of an empty
    // dictionary. This is just in case anyone is relying on that parameter to be a string
    // and not nil.
    [FBSDKTypeUtility dictionary:parameters setObject:@"{}" forKey:@"ud"];
  }

  [FBSDKTypeUtility dictionary:parameters setObject:@(!self.settings.isEventDataUsageLimited).stringValue forKey:@"application_tracking_enabled"];
  [FBSDKTypeUtility dictionary:parameters setObject:@(self.settings.advertiserIDCollectionEnabled).stringValue forKey:@"advertiser_id_collection_enabled"];

  if (userID) {
    [FBSDKTypeUtility dictionary:parameters setObject:userID forKey:@"app_user_id"];
  }

  [self.internalUtility extendDictionaryWithDataProcessingOptions:parameters];

  [FBSDKTypeUtility dictionary:parameters
                     setObject:self.deviceInformationProvider.encodedDeviceInfo
                        forKey:self.deviceInformationProvider.storageKey];

  static dispatch_once_t fetchBundleOnce;
  static NSMutableArray *urlSchemes;

  dispatch_once(&fetchBundleOnce, ^{
    NSBundle *mainBundle = NSBundle.mainBundle;
    urlSchemes = [NSMutableArray new];
    for (NSDictionary<NSString *, id> *fields in [mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"]) {
      NSArray<NSString *> *schemesForType = fields[@"CFBundleURLSchemes"];
      if (schemesForType) {
        [urlSchemes addObjectsFromArray:schemesForType];
      }
    }
  });

  if (urlSchemes.count > 0) {
    [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKBasicUtility JSONStringForObject:urlSchemes error:NULL invalidObjectHandler:NULL] forKey:@"url_schemes"];
  }

  return parameters;
}

- (nullable NSString *)advertiserID
{
  BOOL shouldUseCachedManagerIfAvailable = self.settings.shouldUseCachedValuesForExpensiveMetadata;
  id<FBSDKDynamicFrameworkResolving> dynamicFrameworkResolver = FBSDKDynamicFrameworkLoader.shared;
  return [self _advertiserIDFromDynamicFrameworkResolver:dynamicFrameworkResolver
                                  shouldUseCachedManager:shouldUseCachedManagerIfAvailable];
}

- (nullable NSString *)_advertiserIDFromDynamicFrameworkResolver:(id<FBSDKDynamicFrameworkResolving>)dynamicFrameworkResolver
                                          shouldUseCachedManager:(BOOL)shouldUseCachedManager
{
  if (!self.settings.isAdvertiserIDCollectionEnabled) {
    return nil;
  }

  if (@available(iOS 14.0, *)) {
    if (!self.appEventsConfigurationProvider.cachedAppEventsConfiguration.advertiserIDCollectionEnabled) {
      return nil;
    }
  }

  ASIdentifierManager *manager = [self _asIdentifierManagerWithShouldUseCachedManager:shouldUseCachedManager
                                                             dynamicFrameworkResolver:dynamicFrameworkResolver];
  return manager.advertisingIdentifier.UUIDString;
}

- (ASIdentifierManager *)_asIdentifierManagerWithShouldUseCachedManager:(BOOL)shouldUseCachedManager
                                               dynamicFrameworkResolver:(id<FBSDKDynamicFrameworkResolving>)dynamicFrameworkResolver
{
  if (shouldUseCachedManager && self.cachedAdvertiserIdentifierManager) {
    return self.cachedAdvertiserIdentifierManager;
  }

  Class ASIdentifierManagerClass = [dynamicFrameworkResolver asIdentifierManagerClass];
  ASIdentifierManager *manager = [ASIdentifierManagerClass sharedManager];
  if (shouldUseCachedManager) {
    self.cachedAdvertiserIdentifierManager = manager;
  } else {
    self.cachedAdvertiserIdentifierManager = nil;
  }
  return manager;
}

- (BOOL)isStandardEvent:(nullable NSString *)event
{
  if (!event) {
    return NO;
  }
  return [[self getStandardEvents] containsObject:event];
}

- (NSArray<FBSDKAppEventName> *)getStandardEvents
{
  return @[
    FBSDKAppEventNameCompletedRegistration,
    FBSDKAppEventNameViewedContent,
    FBSDKAppEventNameSearched,
    FBSDKAppEventNameRated,
    FBSDKAppEventNameCompletedTutorial,
    FBSDKAppEventNameAddedToCart,
    FBSDKAppEventNameAddedToWishlist,
    FBSDKAppEventNameInitiatedCheckout,
    FBSDKAppEventNameAddedPaymentInfo,
    FBSDKAppEventNamePurchased,
    FBSDKAppEventNameAchievedLevel,
    FBSDKAppEventNameUnlockedAchievement,
    FBSDKAppEventNameSpentCredits,
    FBSDKAppEventNameContact,
    FBSDKAppEventNameCustomizeProduct,
    FBSDKAppEventNameDonate,
    FBSDKAppEventNameFindLocation,
    FBSDKAppEventNameSchedule,
    FBSDKAppEventNameStartTrial,
    FBSDKAppEventNameSubmitApplication,
    FBSDKAppEventNameSubscribe,
    FBSDKAppEventNameAdImpression,
    FBSDKAppEventNameAdClick
  ];
}

#pragma mark - Internal, for testing

- (void)clearLibraryFiles
{
  [NSFileManager.defaultManager removeItemAtPath:[self.class persistenceFilePath:FBSDK_APPEVENTSUTILITY_ANONYMOUSIDFILENAME]
                                           error:NULL];
  [NSFileManager.defaultManager removeItemAtPath:[self.class persistenceFilePath:@"com-facebook-sdk-AppEventsTimeSpent.json"]
                                           error:NULL];
}

- (void)ensureOnMainThread:(NSString *)methodName className:(NSString *)className
{
  if (!NSThread.isMainThread) {
    NSString *message = [NSString stringWithFormat:@"*** <%@, %@> is not called on the main thread. This can lead to errors.",
                         methodName,
                         className];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                           logEntry:message];
  }
}

- (NSString *)flushReasonToString:(FBSDKAppEventsFlushReason)flushReason
{
  NSString *result = @"Unknown";
  switch (flushReason) {
    case FBSDKAppEventsFlushReasonExplicit:
      result = @"Explicit";
      break;
    case FBSDKAppEventsFlushReasonTimer:
      result = @"Timer";
      break;
    case FBSDKAppEventsFlushReasonSessionChange:
      result = @"SessionChange";
      break;
    case FBSDKAppEventsFlushReasonPersistedEvents:
      result = @"PersistedEvents";
      break;
    case FBSDKAppEventsFlushReasonEventThreshold:
      result = @"EventCountThreshold";
      break;
    case FBSDKAppEventsFlushReasonEagerlyFlushingEvent:
      result = @"EagerlyFlushingEvent";
      break;
  }
  return result;
}

- (void)logAndNotify:(NSString *)msg
{
  [self logAndNotify:msg allowLogAsDeveloperError:YES];
}

- (void)logAndNotify:(NSString *)msg allowLogAsDeveloperError:(BOOL)allowLogAsDeveloperError
{
  NSString *behaviorToLog = FBSDKLoggingBehaviorAppEvents;
  if (allowLogAsDeveloperError) {
    if ([self.settings.loggingBehaviors containsObject:FBSDKLoggingBehaviorDeveloperErrors]) {
      // Rather than log twice, prefer 'DeveloperErrors' if it's set over AppEvents.
      behaviorToLog = FBSDKLoggingBehaviorDeveloperErrors;
    }
  }

  [FBSDKLogger singleShotLogEntry:behaviorToLog logEntry:msg];
  NSError *error = [self.errorFactory errorWithCode:FBSDKErrorAppEventsFlush
                                           userInfo:nil
                                            message:msg
                                    underlyingError:nil];
  [NSNotificationCenter.defaultCenter postNotificationName:FBSDKAppEventsLoggingResultNotification object:error];
}

- (BOOL)       matchString:(NSString *)string
         firstCharacterSet:(NSCharacterSet *)firstCharacterSet
  restOfStringCharacterSet:(NSCharacterSet *)restOfStringCharacterSet
{
  if (string.length == 0) {
    return NO;
  }
  for (NSUInteger i = 0; i < string.length; i++) {
    const unichar c = [string characterAtIndex:i];
    if (i == 0) {
      if (![firstCharacterSet characterIsMember:c]) {
        return NO;
      }
    } else {
      if (![restOfStringCharacterSet characterIsMember:c]) {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)regexValidateIdentifier:(NSString *)identifier
{
  static NSCharacterSet *firstCharacterSet;
  static NSCharacterSet *restOfStringCharacterSet;
  static dispatch_once_t onceToken;
  static NSMutableSet<NSString *> *cachedIdentifiers;
  dispatch_once(&onceToken, ^{
    NSMutableCharacterSet *mutableSet = NSMutableCharacterSet.alphanumericCharacterSet;
    [mutableSet addCharactersInString:@"_"];
    firstCharacterSet = [mutableSet copy];

    [mutableSet addCharactersInString:@"- "];
    restOfStringCharacterSet = [mutableSet copy];
    cachedIdentifiers = [NSMutableSet new];
  });

  @synchronized(self) {
    if (![cachedIdentifiers containsObject:identifier]) {
      if ([self matchString:identifier
                  firstCharacterSet:firstCharacterSet
           restOfStringCharacterSet:restOfStringCharacterSet]) {
        [cachedIdentifiers addObject:identifier];
      } else {
        return NO;
      }
    }
  }
  return YES;
}

- (BOOL)validateIdentifier:(nullable NSString *)identifier
{
  if (identifier == nil || identifier.length == 0 || identifier.length > FBSDK_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH || ![self regexValidateIdentifier:identifier]) {
    [self logAndNotify:[NSString stringWithFormat:@"Invalid identifier: '%@'.  Must be between 1 and %d characters, and must be contain only alphanumerics, _, - or spaces, starting with alphanumeric or _.",
                        identifier, FBSDK_APPEVENTSUTILITY_MAX_IDENTIFIER_LENGTH]];
    return NO;
  }

  return YES;
}

// Given a candidate token (which may be nil), find the real token to string to use.
// Precedence: 1) provided token, 2) current token, 3) app | client token, 4) fully anonymous session.
- (nullable NSString *)tokenStringToUseFor:(nullable FBSDKAccessToken *)token
                      loggingOverrideAppID:(nullable NSString *)loggingOverrideAppID
{
  if (!token) {
    token = FBSDKAccessToken.currentAccessToken;
  }

  NSString *appID = loggingOverrideAppID ?: token.appID ?: self.settings.appID;
  NSString *tokenString = token.tokenString;
  NSString *clientTokenString = self.settings.clientToken;

  if (![appID isEqualToString:token.appID]) {
    // If there's a logging override app id present
    // then we don't want to use the client token since the client token
    // is intended to match up with the primary app id
    // and AppEvents doesn't require a client token.
    if (clientTokenString && loggingOverrideAppID) {
      tokenString = nil;
    } else if (clientTokenString && appID && ([appID isEqualToString:token.appID] || token == nil)) {
      tokenString = [NSString stringWithFormat:@"%@|%@", appID, clientTokenString];
    } else if (appID) {
      tokenString = nil;
    }
  }
  return tokenString;
}

- (NSTimeInterval)unixTimeNow
{
  return round([NSDate date].timeIntervalSince1970);
}

- (NSTimeInterval)convertToUnixTime:(nullable NSDate *)date
{
  return round([date timeIntervalSince1970]);
}

- (BOOL)isDebugBuild
{
#if TARGET_OS_SIMULATOR
  return YES;
#else
  BOOL isDevelopment = NO;

  // There is no provisioning profile in AppStore Apps.
  @try {
    NSData *data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]];
    if (data) {
      const char *bytes = [data bytes];
      NSMutableString *profile = [[NSMutableString alloc] initWithCapacity:data.length];
      for (NSUInteger i = 0; i < data.length; i++) {
        [profile appendFormat:@"%c", bytes[i]];
      }
      // Look for debug value, if detected we're in a development build.
      NSString *cleared = [[profile componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
      isDevelopment = ([cleared rangeOfString:@"<key>get-task-allow</key><true/>"].length > 0);
    }

    return isDevelopment;
  } @catch (NSException *exception) {}

  return NO;
#endif
}

- (BOOL)shouldDropAppEvents
{
  if (@available(iOS 14.0, *)) {
    if ([self.settings advertisingTrackingStatus] == FBSDKAdvertisingTrackingDisallowed && !self.appEventsConfigurationProvider.cachedAppEventsConfiguration.eventCollectionEnabled) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)isSensitiveUserData:(NSString *)text
{
  if (0 == text.length) {
    return NO;
  }

  return [self isEmailAddress:text] || [self isCreditCardNumber:text];
}

- (BOOL)isCreditCardNumber:(NSString *)text
{
  text = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet.decimalDigitCharacterSet invertedSet]] componentsJoinedByString:@""];

  if (text.doubleValue == 0) {
    return NO;
  }

  if (text.length < 9 || text.length > 21) {
    return NO;
  }

  const char *chars = [text cStringUsingEncoding:NSUTF8StringEncoding];
  if (NULL == chars) {
    return NO;
  }

  BOOL isOdd = YES;
  int oddSum = 0;
  int evenSum = 0;

  for (int i = (int)text.length - 1; i >= 0; i--) {
    int digit = chars[i] - '0';

    if (isOdd) {
      oddSum += digit;
    } else {
      evenSum += digit / 5 + (2 * digit) % 10;
    }

    isOdd = !isOdd;
  }

  return ((oddSum + evenSum) % 10 == 0);
}

- (BOOL)isEmailAddress:(NSString *)text
{
  NSString *pattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
  NSUInteger matches = [regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
  return matches > 0;
}

#if DEBUG && FBTEST

- (void)reset
{
  self.appEventsConfigurationProvider = nil;
  self.deviceInformationProvider = nil;
  self.settings = nil;
  self.internalUtility = nil;
  self.errorFactory = nil;
  self.cachedAdvertiserIdentifierManager = nil;
}

#endif

@end
