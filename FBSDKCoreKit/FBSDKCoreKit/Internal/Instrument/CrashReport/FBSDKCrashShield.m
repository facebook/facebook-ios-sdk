/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrashShield.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureDisabling.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKSettingsProtocol.h"

@interface FBSDKCrashShield ()

@property (class, nullable, nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (class, nullable, nonatomic, readonly) id<FBSDKFeatureChecking, FBSDKFeatureDisabling> featureChecking;
@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;

@end

@implementation FBSDKCrashShield

static id<FBSDKGraphRequestFactory> _graphRequestFactory;
static id<FBSDKFeatureChecking, FBSDKFeatureDisabling> _featureChecking;
static NSDictionary<NSString *, NSArray<NSString *> *> *_featureMapping;
static NSDictionary<NSString *, NSNumber *> *_featureForStringMap;
static id<FBSDKSettings> _settings;

+ (id<FBSDKSettings>)settings
{
  return _settings;
}

+ (id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  return _graphRequestFactory;
}

+ (id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking
{
  return _featureChecking;
}

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
          graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking
{
  if (self == FBSDKCrashShield.class) {
    _settings = settings;
    _graphRequestFactory = graphRequestFactory;
    _featureChecking = featureChecking;
  }
}

+ (void)initialize
{
  if (self == FBSDKCrashShield.class) {
    _featureMapping =
    @{
      @"AAM" : @[
        @"FBSDKMetadataIndexer",
      ],
      @"AEM" : @ [
        @"FBAEMConfiguration",
        @"FBAEMEvent",
        @"FBAEMInvocation",
        @"FBAEMReporter",
        @"FBAEMRule",
      ],
      @"CodelessEvents" : @[
        @"FBSDKCodelessIndexer",
        @"FBSDKEventBinding",
        @"FBSDKEventBindingManager",
        @"FBSDKViewHierarchy",
        @"FBSDKCodelessPathComponent",
        @"FBSDKCodelessParameterComponent",
      ],
      @"RestrictiveDataFiltering" : @[
        @"FBSDKRestrictiveDataFilterManager",
      ],
      @"ErrorReport" : @[
        @"FBSDKErrorReport",
      ],
      @"PrivacyProtection" : @[
        @"FBSDKModelManager",
      ],
      @"SuggestedEvents" : @[
        @"FBSDKSuggestedEventsIndexer",
        @"FBSDKFeatureExtractor",
      ],
      @"IntelligentIntegrity" : @[
        @"FBSDKIntegrityManager",
      ],
      @"EventDeactivation" : @[
        @"FBSDKEventDeactivationManager",
      ],
      @"SKAdNetworkConversionValue" : @[
        @"FBSDKSKAdNetworkReporter",
        @"FBSDKSKAdNetworkConversionConfiguration",
        @"FBSDKSKAdNetworkRule",
        @"FBSDKSKAdNetworkEvent",
      ],
    };

    _featureForStringMap = @{
      @"CoreKit" : @(FBSDKFeatureCore),
      @"AppEvents" : @(FBSDKFeatureAppEvents),
      @"CodelessEvents" : @(FBSDKFeatureCodelessEvents),
      @"RestrictiveDataFiltering" : @(FBSDKFeatureRestrictiveDataFiltering),
      @"AAM" : @(FBSDKFeatureAAM),
      @"PrivacyProtection" : @(FBSDKFeaturePrivacyProtection),
      @"SuggestedEvents" : @(FBSDKFeatureSuggestedEvents),
      @"IntelligentIntegrity" : @(FBSDKFeatureIntelligentIntegrity),
      @"ModelRequest" : @(FBSDKFeatureModelRequest),
      @"EventDeactivation" : @(FBSDKFeatureEventDeactivation),
      @"SKAdNetwork" : @(FBSDKFeatureSKAdNetwork),
      @"SKAdNetworkConversionValue" : @(FBSDKFeatureSKAdNetworkConversionValue),
      @"Instrument" : @(FBSDKFeatureInstrument),
      @"CrashReport" : @(FBSDKFeatureCrashReport),
      @"CrashShield" : @(FBSDKFeatureCrashShield),
      @"ErrorReport" : @(FBSDKFeatureErrorReport),
      @"ATELogging" : @(FBSDKFeatureATELogging),
      @"AEM" : @(FBSDKFeatureAEM),
      @"LoginKit" : @(FBSDKFeatureLogin),
      @"ShareKit" : @(FBSDKFeatureShare),
      @"GamingServicesKit" : @(FBSDKFeatureGamingServices),
    };
  }
}

+ (void)analyze:(NSArray<NSDictionary<NSString *, id> *> *)crashLogs
{
  NSMutableSet<NSString *> *disabledFeatures = [NSMutableSet set];
  for (NSDictionary<NSString *, id> *crashLog in crashLogs) {
    NSArray<NSString *> *callstack = crashLog[@"callstack"];
    NSString *featureName = [self _getFeature:callstack];
    if (featureName) {
      [_featureChecking disableFeature:[self featureForString:featureName]];
      [disabledFeatures addObject:featureName];
      continue;
    }
  }
  if ([self.settings isDataProcessingRestricted]) {
    return;
  }
  if (disabledFeatures.count > 0) {
    NSDictionary<NSString *, id> *disabledFeatureLog = @{@"feature_names" : disabledFeatures.allObjects,
                                                         @"timestamp" : [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]], };
    NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:disabledFeatureLog options:0 error:nil];
    if (jsonData) {
      NSString *disabledFeatureReport = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      if (disabledFeatureReport) {
        id<FBSDKGraphRequest> request = [_graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/instruments", [self.settings appID]]
                                                                                   parameters:@{@"crash_shield" : disabledFeatureReport}
                                                                                   HTTPMethod:FBSDKHTTPMethodPOST];

        [request startWithCompletion:nil];
      }
    }
  }
}

#pragma mark - Private Methods
+ (int)featureForString:(NSString *)featureName
{
  NSNumber *feature = [FBSDKTypeUtility dictionary:_featureForStringMap objectForKey:featureName ofType:NSObject.class];
  return feature.intValue;
}

+ (nullable NSString *)_getFeature:(NSArray<NSString *> *)callstack
{
  NSArray<NSString *> *validCallstack = [FBSDKTypeUtility arrayValue:callstack];
  NSArray<NSString *> *featureNames = _featureMapping.allKeys;
  for (NSString *entry in validCallstack) {
    NSString *className = [self _getClassName:[FBSDKTypeUtility coercedToStringValue:entry]];
    for (NSString *featureName in featureNames) {
      NSArray<NSString *> *classArray = [FBSDKTypeUtility dictionary:_featureMapping objectForKey:featureName ofType:NSObject.class];
      if (className && [classArray containsObject:className]) {
        return featureName;
      }
    }
  }
  return nil;
}

+ (nullable NSString *)_getClassName:(NSString *)entry
{
  NSString *validEntry = [FBSDKTypeUtility coercedToStringValue:entry];
  NSArray<NSString *> *items = [validEntry componentsSeparatedByString:@" "];
  NSString *className = nil;
  // parse class name only from an entry in format "-[className functionName]+offset"
  // or "+[className functionName]+offset"
  if ([items.firstObject hasPrefix:@"+["] || [items.firstObject hasPrefix:@"-["]) {
    className = [items.firstObject substringFromIndex:2];
  }
  return className;
}

#if DEBUG

+ (void)reset
{
  _settings = nil;
  _graphRequestFactory = nil;
  _featureChecking = nil;
}

#endif

@end
