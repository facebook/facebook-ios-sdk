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

#import "FBSDKFeatureManager.h"

#import "FBSDKGateKeeperManager.h"
#import "FBSDKGateKeeperManaging.h"
#import "FBSDKSettings.h"
#import "NSUserDefaults+FBSDKDataPersisting.h"

static NSString *const FBSDKFeatureManagerPrefix = @"com.facebook.sdk:FBSDKFeatureManager.FBSDKFeature";

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKFeatureManager ()

@property (nullable, nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nullable, nonatomic) id<FBSDKDataPersisting> store;

@end

@implementation FBSDKFeatureManager

#pragma mark - Public methods

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal is to move from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
+ (instancetype)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

- (instancetype)init
{
  return [self initWithGateKeeperManager:FBSDKGateKeeperManager.class
                                   store:NSUserDefaults.standardUserDefaults];
}

- (instancetype)initWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                                    store:(id<FBSDKDataPersisting>)store
{
  if ((self = [super init])) {
    _gateKeeperManager = gateKeeperManager;
    _store = store;
  }
  return self;
}

+ (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock
{
  [self.shared checkFeature:feature completionBlock:completionBlock];
}

- (void)checkFeature:(FBSDKFeature)feature
     completionBlock:(FBSDKFeatureManagerBlock)completionBlock
{
  // check if the feature is locally disabled by Crash Shield first
  NSString *version = [self.store stringForKey:[FBSDKFeatureManagerPrefix stringByAppendingString:[self.class featureName:feature]]];
  if (version && [version isEqualToString:[FBSDKSettings sdkVersion]]) {
    if (completionBlock) {
      completionBlock(false);
    }
    return;
  }
  // check gk
  [self.gateKeeperManager loadGateKeepers:^(NSError *_Nullable error) {
    if (completionBlock) {
      completionBlock([self isEnabled:feature]);
    }
  }];
}

- (BOOL)isEnabled:(FBSDKFeature)feature
{
  if (FBSDKFeatureCore == feature) {
    return YES;
  }

  FBSDKFeature parentFeature = [self.class getParentFeature:feature];
  if (parentFeature == feature) {
    return [self checkGK:feature];
  } else {
    return [self isEnabled:parentFeature] && [self checkGK:feature];
  }
}

- (void)disableFeature:(NSString *)featureName
{
  [self.store setObject:[FBSDKSettings sdkVersion] forKey:[FBSDKFeatureManagerPrefix stringByAppendingString:featureName]];
}

#pragma mark - Private methods

+ (FBSDKFeature)getParentFeature:(FBSDKFeature)feature
{
  if ((feature & 0xFF) > 0) {
    return feature & 0xFFFFFF00;
  } else if ((feature & 0xFF00) > 0) {
    return feature & 0xFFFF0000;
  } else if ((feature & 0xFF0000) > 0) {
    return feature & 0xFF000000;
  } else {
    return 0;
  }
}

- (BOOL)checkGK:(FBSDKFeature)feature
{
  NSString *key = [NSString stringWithFormat:@"FBSDKFeature%@", [self.class featureName:feature]];
  BOOL defaultValue = [self.class defaultStatus:feature];

  return [self.gateKeeperManager boolForKey:key
                               defaultValue:defaultValue];
}

+ (NSString *)featureName:(FBSDKFeature)feature
{
  NSString *featureName;
  switch (feature) {
    case FBSDKFeatureCore: featureName = @"CoreKit"; break;
    case FBSDKFeatureAppEvents: featureName = @"AppEvents"; break;
    case FBSDKFeatureCodelessEvents: featureName = @"CodelessEvents"; break;
    case FBSDKFeatureRestrictiveDataFiltering: featureName = @"RestrictiveDataFiltering"; break;
    case FBSDKFeatureAAM: featureName = @"AAM"; break;
    case FBSDKFeaturePrivacyProtection: featureName = @"PrivacyProtection"; break;
    case FBSDKFeatureSuggestedEvents: featureName = @"SuggestedEvents"; break;
    case FBSDKFeatureIntelligentIntegrity: featureName = @"IntelligentIntegrity"; break;
    case FBSDKFeatureModelRequest: featureName = @"ModelRequest"; break;
    case FBSDKFeatureEventDeactivation: featureName = @"EventDeactivation"; break;
    case FBSDKFeatureSKAdNetwork: featureName = @"SKAdNetwork"; break;
    case FBSDKFeatureSKAdNetworkConversionValue: featureName = @"SKAdNetworkConversionValue"; break;
    case FBSDKFeatureInstrument: featureName = @"Instrument"; break;
    case FBSDKFeatureCrashReport: featureName = @"CrashReport"; break;
    case FBSDKFeatureCrashShield: featureName = @"CrashShield"; break;
    case FBSDKFeatureErrorReport: featureName = @"ErrorReport"; break;
    case FBSDKFeatureATELogging: featureName = @"ATELogging"; break;
    case FBSDKFeatureAEM: featureName = @"AEM"; break;
    case FBSDKFeatureLogin: featureName = @"LoginKit"; break;
    case FBSDKFeatureShare: featureName = @"ShareKit"; break;
    case FBSDKFeatureGamingServices: featureName = @"GamingServicesKit"; break;
  }

  return featureName;
}

+ (BOOL)defaultStatus:(FBSDKFeature)feature
{
  switch (feature) {
    case FBSDKFeatureRestrictiveDataFiltering:
    case FBSDKFeatureEventDeactivation:
    case FBSDKFeatureInstrument:
    case FBSDKFeatureCrashReport:
    case FBSDKFeatureCrashShield:
    case FBSDKFeatureErrorReport:
    case FBSDKFeatureAAM:
    case FBSDKFeaturePrivacyProtection:
    case FBSDKFeatureSuggestedEvents:
    case FBSDKFeatureIntelligentIntegrity:
    case FBSDKFeatureModelRequest:
    case FBSDKFeatureATELogging:
    case FBSDKFeatureAEM:
    case FBSDKFeatureSKAdNetwork:
    case FBSDKFeatureSKAdNetworkConversionValue:
      return NO;
    case FBSDKFeatureLogin:
    case FBSDKFeatureShare:
    case FBSDKFeatureCore:
    case FBSDKFeatureAppEvents:
    case FBSDKFeatureCodelessEvents:
    case FBSDKFeatureGamingServices:
      return YES;
  }
}

@end

NS_ASSUME_NONNULL_END
