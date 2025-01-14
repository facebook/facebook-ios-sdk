/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrashObserver+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKFeatureChecking.h"
#import "FBSDKGraphRequestFactoryProtocol.h"
#import "FBSDKGraphRequestHTTPMethod.h"
#import "FBSDKGraphRequestProtocol.h"
#import "FBSDKInternalUtility+Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKCrashObserver

@synthesize prefixes, frameworks;

- (instancetype)initWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                   graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                              settings:(id<FBSDKSettings>)settings
                          crashHandler:(id<FBSDKCrashHandler>)crashHandler
{
  if ((self = [super init])) {
    prefixes = @[@"FBSDK", @"_FBSDK"];
    frameworks = @[@"FBSDKCoreKit",
                   @"FBSDKLoginKit",
                   @"FBSDKShareKit",
                   @"FBSDKGamingServicesKit"];
    _featureChecker = featureChecker;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
    _crashHandler = crashHandler;
  }
  return self;
}

- (void)didReceiveCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs
{
  if ([_settings isDataProcessingRestricted]) {
    return;
  }
  if (0 == processedCrashLogs.count) {
    [self.crashHandler clearCrashReportFiles];
    return;
  }
  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:processedCrashLogs options:0 error:nil];
  if (jsonData) {
    NSString *crashReports = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSMutableDictionary<NSString *, NSString *> *parameters = [NSMutableDictionary new];
    [FBSDKTypeUtility dictionary:parameters setObject:(crashReports ?: @"") forKey:@"crash_reports"];
    [FBSDKInternalUtility.sharedUtility extendDictionaryWithDataProcessingOptions:parameters];
    id<FBSDKGraphRequest> request = [_graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/instruments", [_settings appID]]
                                                                               parameters:parameters
                                                                              tokenString:nil
                                                                               HTTPMethod:FBSDKHTTPMethodPOST
                                                                                    flags:FBSDKGraphRequestFlagNone
                                                        useAlternativeDefaultDomainPrefix:NO];

    [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      if (!error && [result isKindOfClass:[NSDictionary<NSString *, id> class]] && result[@"success"]) {
        [self.crashHandler clearCrashReportFiles];
      }
    }];
  }
  [_featureChecker checkFeature:FBSDKFeatureCrashShield completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKCrashShield analyze:processedCrashLogs];
    }
  }];
}

@end

NS_ASSUME_NONNULL_END
