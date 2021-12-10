/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKIntegrityManager.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGateKeeperManaging.h"
#import "FBSDKIntegrityProcessing.h"

@interface FBSDKIntegrityManager ()

@property (nonatomic) Class<FBSDKGateKeeperManaging> gateKeeperManager;
@property (nonatomic, weak) id<FBSDKIntegrityProcessing> integrityProcessor;
@property (nonatomic) BOOL isIntegrityEnabled;
@property (nonatomic) BOOL isSampleEnabled;

@end

@implementation FBSDKIntegrityManager

- (instancetype)initWithGateKeeperManager:(Class<FBSDKGateKeeperManaging>)gateKeeperManager
                       integrityProcessor:(id<FBSDKIntegrityProcessing>)integrityProcessor
{
  if ((self = [super init])) {
    _gateKeeperManager = gateKeeperManager;
    _integrityProcessor = integrityProcessor;
  }
  return self;
}

- (void)enable
{
  self.isIntegrityEnabled = YES;
  self.isSampleEnabled = [self.gateKeeperManager boolForKey:@"FBSDKFeatureIntegritySample" defaultValue:false];
}

// Unused parameter eventName is required for conformance to shared protocol for processing app events.
- (nullable NSDictionary<NSString *, id> *)processParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                   eventName:(NSString *)eventName
{
  if (!self.isIntegrityEnabled || parameters.count == 0) {
    return parameters;
  }
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
  NSMutableDictionary<NSString *, id> *restrictiveParams = [NSMutableDictionary dictionary];

  for (NSString *key in [parameters keyEnumerator]) {
    NSString *valueString = [FBSDKTypeUtility coercedToStringValue:parameters[key]];
    BOOL shouldFilter = [self.integrityProcessor processIntegrity:key] || [self.integrityProcessor processIntegrity:valueString];
    if (shouldFilter) {
      [FBSDKTypeUtility dictionary:restrictiveParams setObject:self.isSampleEnabled ? valueString : @"" forKey:key];
      [params removeObjectForKey:key];
    }
  }
  if ([restrictiveParams count] > 0) {
    NSString *restrictiveParamsJSONString = [FBSDKBasicUtility JSONStringForObject:restrictiveParams
                                                                             error:NULL
                                                              invalidObjectHandler:NULL];
    [FBSDKTypeUtility dictionary:params setObject:restrictiveParamsJSONString forKey:@"_onDeviceParams"];
  }
  return [params copy];
}

@end

#endif
