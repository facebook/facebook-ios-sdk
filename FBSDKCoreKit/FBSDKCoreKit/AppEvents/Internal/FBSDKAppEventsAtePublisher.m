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

#import "FBSDKAppEventsAtePublisher.h"

#import "FBSDKAppEventsDeviceInfo.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKDataPersisting.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings+Internal.h"

@interface FBSDKAppEventsAtePublisher ()

@property (nullable, nonatomic, assign) id<FBSDKDataPersisting> store;

@end

@implementation FBSDKAppEventsAtePublisher

- (nullable instancetype)initWithAppIdentifier:(NSString *)appIdentifier
                                         store:(id<FBSDKDataPersisting>)store
{
  if ((self = [self init])) {
    NSString *identifier = [FBSDKTypeUtility coercedToStringValue:appIdentifier];
    if (identifier.length == 0) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"Missing [FBSDKAppEvents appID] for [FBSDKAppEvents publishATE:]"];
      return nil;
    }
    _appIdentifier = identifier;
    _store = store;
  }
  return self;
}

- (void)publishATE
{
  NSString *lastATEPingString = [NSString stringWithFormat:@"com.facebook.sdk:lastATEPing%@", self.appIdentifier];
  id lastPublishDate = [self.store objectForKey:lastATEPingString];
  if ([lastPublishDate isKindOfClass:[NSDate class]] && [(NSDate *)lastPublishDate timeIntervalSinceNow] * -1 < 24 * 60 * 60) {
    return;
  }

  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:parameters setObject:@"CUSTOM_APP_EVENTS" forKey:@"event"];

  NSOperatingSystemVersion operatingSystemVersion = [FBSDKInternalUtility operatingSystemVersion];
  NSString *osVersion = [NSString stringWithFormat:@"%ti.%ti.%ti",
                         operatingSystemVersion.majorVersion,
                         operatingSystemVersion.minorVersion,
                         operatingSystemVersion.patchVersion];

  NSArray *event = @[
    @{
      @"_eventName" : @"fb_mobile_ate_status",
      @"ate_status" : @([FBSDKSettings advertisingTrackingStatus]).stringValue,
      @"os_version" : osVersion,
    }
  ];
  [FBSDKTypeUtility dictionary:parameters setObject:[FBSDKBasicUtility JSONStringForObject:event error:NULL invalidObjectHandler:NULL] forKey:@"custom_events"];

  [FBSDKAppEventsDeviceInfo extendDictionaryWithDeviceInfo:parameters];

  NSString *path = [NSString stringWithFormat:@"%@/activities", self.appIdentifier];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                 parameters:parameters
                                                                tokenString:nil
                                                                 HTTPMethod:FBSDKHTTPMethodPOST
                                                                      flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
  __block id<FBSDKDataPersisting> weakStore = self.store;
  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
    if (!error) {
      [weakStore setObject:[NSDate date] forKey:lastATEPingString];
    }
  }];
}

@end
