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
#import "FBSDKFeatureCheckerFactory.h"
#import "FBSDKFeatureCheckerProviding.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKGraphRequestProviding.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettings+SettingsLogging.h"
#import "FBSDKSettings+SettingsProtocols.h"
#import "FBSDKSettingsProtocol.h"

@implementation FBSDKCrashObserver
{
  Class<FBSDKFeatureChecking> _featureChecker;
  id<FBSDKGraphRequestProviding> _requestProvider;
  id<FBSDKSettings> _settings;
}

@synthesize prefixes, frameworks;

- (instancetype)init
{
  return [self initWithFeatureManagerProvider:[FBSDKFeatureCheckerFactory new]
                         graphRequestProvider:[FBSDKGraphRequestFactory new]
                                     settings:FBSDKSettings.sharedSettings];
}

- (instancetype)initWithFeatureManagerProvider:(id<FBSDKFeatureCheckerProviding>)featureManagerProvider
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
    _featureChecker = [featureManagerProvider createFeatureChecker];
    _requestProvider = requestProvider;
    _settings = settings;
  }
  return self;
}

+ (void)enable
{
  [FBSDKCrashHandler addObserver:[FBSDKCrashObserver sharedInstance]];
}

+ (FBSDKCrashObserver *)sharedInstance
{
  static FBSDKCrashObserver *_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[self alloc] init];
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

    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
