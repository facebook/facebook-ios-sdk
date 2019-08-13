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

#import "FBSDKCrashHandler.h"

#import "FBSDKCrashStorage.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKLibAnalyzer.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"

static NSUncaughtExceptionHandler *previousExceptionHandler = NULL;

@implementation FBSDKCrashHandler

# pragma mark - Class Methods

+ (void)initialize
{
  [self enableCrashLogger];
}

+ (void)enableCrashLogger
{
  if ([FBSDKSettings isInstrumentEnabled] && [FBSDKFeatureManager isEnabled:FBSDKFeatureCrashReport]) {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
      [FBSDKCrashHandler installExceptionsHandler];
      [FBSDKCrashStorage generateMethodMapping];
      [self uploadCrashLogs];
    });
  } else {
    [FBSDKCrashStorage clearCrashReportFiles:nil];
  }
}

+ (void)uploadCrashLogs
{
  NSArray<NSDictionary<NSString *, id> *> *processedCrashLogs = [FBSDKCrashStorage getProcessedCrashLogs];
  if (0 == processedCrashLogs) {
    return;
  }
  NSMutableArray<NSString *> *encodedCrashLogs = [NSMutableArray array];
  for (NSDictionary<NSString *, id> * crashLog in processedCrashLogs) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:crashLog options:0 error:nil];
    if (data) {
      NSString *encodedCrashLog = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      if (encodedCrashLog) {
        [encodedCrashLogs addObject:encodedCrashLog];
      }
    }
  }
  // TODO(T48499181): add graph request to send crash log
}

# pragma mark handler function

+ (void)installExceptionsHandler
{
  NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

  if (currentHandler != FBSDKExceptionHandler) {
    previousExceptionHandler = currentHandler;
    NSSetUncaughtExceptionHandler(&FBSDKExceptionHandler);
  }
}

+ (void)uninstallExceptionsHandler
{
  NSSetUncaughtExceptionHandler(previousExceptionHandler);
  previousExceptionHandler = nil;
}

static void FBSDKExceptionHandler(NSException *exception)
{
  [FBSDKCrashStorage saveException:exception];
  if (previousExceptionHandler) {
    previousExceptionHandler(exception);
  }
}

@end
