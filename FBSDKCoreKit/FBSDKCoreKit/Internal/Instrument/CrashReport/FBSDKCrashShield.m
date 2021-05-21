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

#import "FBSDKCrashShield.h"

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureDisabling.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestHTTPMethod.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsProtocol.h"

@interface FBSDKCrashShield ()

@property (class, nullable, nonatomic, readonly) id<FBSDKGraphRequestProviding> requestProvider;
@property (class, nullable, nonatomic, readonly) id<FBSDKFeatureChecking, FBSDKFeatureDisabling> featureChecking;
@property (class, nullable, nonatomic, readonly) id<FBSDKSettings> settings;

@end

@implementation FBSDKCrashShield

static id<FBSDKGraphRequestProviding> _requestProvider;
static id<FBSDKFeatureChecking, FBSDKFeatureDisabling> _featureChecking;
static NSDictionary<NSString *, NSArray<NSString *> *> *_featureMapping;
static NSDictionary<NSString *, NSNumber *> *_featureForStringMap;
static id<FBSDKSettings> _settings;

+ (id<FBSDKSettings>)settings
{
  return _settings;
}

+ (id<FBSDKGraphRequestProviding>)requestProvider
{
  return _requestProvider;
}

+ (id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking
{
  return _featureChecking;
}

+ (void)configureWithSettings:(id<FBSDKSettings>)settings
              requestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
              featureChecking:(id<FBSDKFeatureChecking, FBSDKFeatureDisabling>)featureChecking
{
  if (self == [FBSDKCrashShield class]) {
    _settings = settings;
    _requestProvider = requestProvider;
    _featureChecking = featureChecking;
  }
}

+ (void)initialize
{
  if (self == [FBSDKCrashShield class]) {
    _featureMapping =
    @{
      @"AEM" : @ [
        @"FBSDKAEMConfiguration",
        @"FBSDKAEMEvent",
        @"FBSDKAEMInvocation",
        @"FBSDKAEMReporter",
        @"FBSDKAEMRule",
      ],
      @"AAM" : @[
        @"FBSDKMetadataIndexer",
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
    NSDictionary<NSString *, id> *disabledFeatureLog = @{@"feature_names" : [disabledFeatures allObjects],
                                                         @"timestamp" : [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]], };
    NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:disabledFeatureLog options:0 error:nil];
    if (jsonData) {
      NSString *disabledFeatureReport = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      if (disabledFeatureReport) {
        id<FBSDKGraphRequest> request = [_requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/instruments", [self.settings appID]]
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
  if (items.count > 0 && ([[FBSDKTypeUtility array:items objectAtIndex:0] hasPrefix:@"+["] || [[FBSDKTypeUtility array:items objectAtIndex:0] hasPrefix:@"-["])) {
    className = [[FBSDKTypeUtility array:items objectAtIndex:0] substringFromIndex:2];
  }
  return className;
}

#if DEBUG
 #if FBSDKTEST

+ (void)reset
{
  _settings = nil;
  _requestProvider = nil;
  _featureChecking = nil;
}

 #endif
#endif

@end
