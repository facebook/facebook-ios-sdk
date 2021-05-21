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

#import "FBSDKCrashObserver.h"

#import "FBSDKCrashShield.h"
#import "FBSDKFeatureChecking.h"
#import "FBSDKFeatureManager+FeatureChecking.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestHTTPMethod.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+SettingsLogging.h"
#import "FBSDKSettings+SettingsProtocols.h"
#import "FBSDKSettingsProtocol.h"

@interface FBSDKCrashObserver ()

@property (nonatomic, strong) id<FBSDKFeatureChecking> featureChecker;
@property (nonatomic, strong) id<FBSDKGraphRequestProviding> requestProvider;
@property (nonatomic, strong) id<FBSDKSettings> settings;

@end

@implementation FBSDKCrashObserver

@synthesize prefixes, frameworks;

- (instancetype)init
{
  return [self initWithFeatureChecker:FBSDKFeatureManager.shared
                 graphRequestProvider:[FBSDKGraphRequestFactory new]
                             settings:FBSDKSettings.sharedSettings];
}

- (instancetype)initWithFeatureChecker:(id<FBSDKFeatureChecking>)featureChecker
                  graphRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
                              settings:(id<FBSDKSettings>)settings
{
  if ((self = [super init])) {
    prefixes = @[@"FBSDK", @"_FBSDK"];
    frameworks = @[@"FBSDKCoreKit",
                   @"FBSDKLoginKit",
                   @"FBSDKShareKit",
                   @"FBSDKGamingServicesKit",
                   @"FBSDKTVOSKit"];
    _featureChecker = featureChecker;
    _requestProvider = requestProvider;
    _settings = settings;
  }
  return self;
}

+ (instancetype)shared
{
  static FBSDKCrashObserver *_sharedInstance;
  static dispatch_once_t nonce;
  dispatch_once(&nonce, ^{
    _sharedInstance = [self new];
  });
  return _sharedInstance;
}

- (void)didReceiveCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs
{
  if ([_settings isDataProcessingRestricted]) {
    return;
  }
  if (0 == processedCrashLogs.count) {
    [FBSDKCrashHandler clearCrashReportFiles];
    return;
  }
  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:processedCrashLogs options:0 error:nil];
  if (jsonData) {
    NSString *crashReports = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    id<FBSDKGraphRequest> request = [_requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/instruments", [_settings appID]]
                                                                           parameters:@{@"crash_reports" : crashReports ?: @""}
                                                                           HTTPMethod:FBSDKHTTPMethodPOST];

    [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      if (!error && [result isKindOfClass:[NSDictionary class]] && result[@"success"]) {
        [FBSDKCrashHandler clearCrashReportFiles];
      }
    }];
  }
  [_featureChecker checkFeature:FBSDKFeatureCrashShield completionBlock:^(BOOL enabled) {
    if (enabled) {
      [FBSDKCrashShield analyze:processedCrashLogs];
    }
  }];
}

#if DEBUG
 #if FBSDKTEST
- (id<FBSDKSettings>)settings
{
  return _settings;
}

 #endif
#endif

@end
