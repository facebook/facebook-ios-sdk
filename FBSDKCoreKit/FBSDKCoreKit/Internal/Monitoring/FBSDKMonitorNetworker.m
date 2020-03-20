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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKMonitorNetworker.h"

@interface FBSDKMonitorNetworker ()
@end

@implementation FBSDKMonitorNetworker

+ (void)sendEntries:(NSArray<FBSDKMonitorEntry *> *)entries
{
  NSString *appID = [FBSDKSettings appID];

  if (appID) {
    NSString *path = [NSString stringWithFormat:@"%@/monitorings", appID];

    NSDictionary *payload = @{@"monitorings": [self JSONStringForEntries:entries] ?: @"[]"};
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                   parameters:payload
                                                                  tokenString:nil
                                                                   HTTPMethod:FBSDKHTTPMethodPOST
                                                                        flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError | FBSDKGraphRequestFlagDisableErrorRecovery];
    // Not handling errors for now since we do not want to disrupt developer or retry.
    [request startWithCompletionHandler:nil];
  }
}

+ (nullable NSString *)JSONStringForEntries:(NSArray<FBSDKMonitorEntry *> *)entries
{
  NSMutableArray *jsonEntries = [NSMutableArray array];

  for (FBSDKMonitorEntry *entry in entries) {
    [jsonEntries addObject:entry.dictionaryRepresentation];
  }

  return [FBSDKBasicUtility JSONStringForObject:jsonEntries
                                          error:NULL
                           invalidObjectHandler:NULL];
}

@end
