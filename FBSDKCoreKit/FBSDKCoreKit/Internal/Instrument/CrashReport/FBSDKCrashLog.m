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

#import "FBSDKCrashLog.h"

#import "FBSDKCrashHandler.h"
#import "FBSDKCrashStorage.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKLibAnalyzer.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"

static NSString *const FBSDKPlistInfoKey = @"FBSDKCrashLoggerEnabled";

@implementation FBSDKCrashLog

# pragma mark - Forward Declarations

void uncaughtExceptionHandler(NSException *exception);

# pragma mark - Class Methods

+ (void)initialize
{
  [[FBSDKCrashLog sharedInstance] enableCrashLogger];
}

+ (FBSDKCrashLog *)sharedInstance
{
  static FBSDKCrashLog*_sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [[self alloc] init];
  });
  return _sharedInstance;
}

- (void)enableCrashLogger
{
  if ([FBSDKSettings isInstrumentEnabled] && [FBSDKFeatureManager isEnabled:FBSDKFeatureCrashReport]) {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
      [FBSDKCrashHandler installExceptionsHandler];
      [FBSDKLibAnalyzer generateMethodsTable];
      [FBSDKCrashHandler processCrash:^(NSDictionary<NSString *, id> *crashInfo){
        [FBSDKLibAnalyzer processCrashInfo:crashInfo block:[self reportBlock]];
      }];
    });
  } else {
    [FBSDKCrashStorage clearCrashInfo];
  }
}

- (FBSDKCrashLoggerReportBlock)reportBlock
{
  return ^(NSDictionary<NSString *, id> *crashInfo){
    // Encode Crash Info to be either NSString & NSNumber
    NSMutableDictionary<NSString *, id> *encodedCrashInfo = [NSMutableDictionary dictionaryWithDictionary:crashInfo];
    [crashInfo enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if (![obj isKindOfClass:[NSString class]] && ![obj isKindOfClass:[NSNumber class]]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
          [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                 logEntry:[NSString stringWithFormat: @"Failed to JSONSerialize crash report %@", crashInfo]];
          return;
        } else {
          NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
          encodedCrashInfo[key] = jsonString;
        }
      }
    }];
    // TODO(T48499181): add graph request to send crash log
  };
}

@end
