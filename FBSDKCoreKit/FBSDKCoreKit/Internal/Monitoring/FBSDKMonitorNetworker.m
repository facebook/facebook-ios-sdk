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

#import <sys/utsname.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKMonitorNetworker.h"

static NSString * const FBSDKAppIdentifierKey = @"id";
static NSString * const FBSDKBundleIdentifierKey = @"unique_application_identifier";
static NSString * const FBSDKDeviceModelKey = @"device_model";
static NSString * const FBSDKMonitoringsKey = @"monitorings";
static NSString * const FBSDKOsVersionKey = @"device_os_version";


@interface FBSDKMonitorNetworker ()
@end

@implementation FBSDKMonitorNetworker

+ (void)sendEntries:(NSArray<id<FBSDKMonitorEntry>> *)entries
{
  NSDictionary *postBody = [self postBodyWithEntries:entries];

  // don't make request without a post body
  if (postBody) {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/monitorings"
                                                                   parameters:postBody
                                                                  tokenString:nil
                                                                   HTTPMethod:FBSDKHTTPMethodPOST
                                                                        flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
    // Not handling errors for now since we do not want to disrupt developer or retry.
    [request startWithCompletionHandler:nil];
  }
}

+ (NSDictionary<NSString *, id> *)postBodyWithEntries:(NSArray<id<FBSDKMonitorEntry>> *)entries
{
  NSString *appID = [FBSDKSettings appID];

  if (!appID) {
    return nil;
  }

  NSMutableDictionary *payload = [NSMutableDictionary dictionary];
  [FBSDKTypeUtility dictionary:payload setObject:[self JSONStringForEntries:entries] ?: @[] forKey:FBSDKMonitoringsKey];
  [FBSDKTypeUtility dictionary:payload setObject:appID forKey:FBSDKAppIdentifierKey];
  [FBSDKTypeUtility dictionary:payload setObject:[self deviceModel] forKey:FBSDKDeviceModelKey];
  [FBSDKTypeUtility dictionary:payload setObject:NSBundle.mainBundle.bundleIdentifier forKey:FBSDKBundleIdentifierKey];
  [FBSDKTypeUtility dictionary:payload setObject:UIDevice.currentDevice.systemVersion forKey:FBSDKOsVersionKey];

  return payload;
}

+ (nullable NSString *)JSONStringForEntries:(NSArray<id<FBSDKMonitorEntry>> *)entries
{
  NSMutableArray *jsonEntries = [NSMutableArray array];

  for (id<FBSDKMonitorEntry> entry in entries) {
    [FBSDKTypeUtility array:jsonEntries addObject:entry.dictionaryRepresentation];
  }

  return [FBSDKBasicUtility JSONStringForObject:jsonEntries
                                          error:NULL
                           invalidObjectHandler:NULL];
}

+ (NSString * _Nonnull)deviceModel
{
  struct utsname systemInfo;
  uname(&systemInfo);

  return [NSString stringWithCString:systemInfo.machine
                            encoding:NSUTF8StringEncoding];
}

@end
