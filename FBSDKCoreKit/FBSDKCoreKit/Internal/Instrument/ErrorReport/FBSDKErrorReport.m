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

#import "FBSDKErrorReport.h"

#import "FBSDKLogger.h"
#import "FBSDKSettings.h"

@implementation FBSDKErrorReport

static NSString *ErrorReportStorageDirName = @"instrument/";
static NSString *directoryPath;

NSString *const kFBSDKErrorCode = @"error_code";
NSString *const kFBSDKErrorDomain = @"error_domain";
NSString *const kFBSDKErrorTimestamp = @"error_time_stamp";

# pragma mark - Class Methods

+ (void)initialize
{
  NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:ErrorReportStorageDirName];
  if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
    if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL]) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational formatString:@"Failed to create library at %@", dirPath];
    }
  }
  directoryPath = dirPath;
}

- (void)enable
{
  // TODO (linajin) T48556791 Error Report Logger behavior upon APP loading
}

+ (void)saveError:(NSInteger)errorCode
      errorDomain:(NSErrorDomain)errorDomain
          message:(nullable NSString *)message
{
  NSString *timestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
  [self saveErrorInfoToDisk: @{
                               kFBSDKErrorCode:@(errorCode),
                               kFBSDKErrorDomain:errorDomain,
                               kFBSDKErrorTimestamp:timestamp,
                               }];
}

+ (NSDictionary<NSString *,id> *)loadErrorInfo
{
  // TODO (linajin) T48556791 Error Report Logger behavior upon APP loading
  return @{};
}

+ (void)clearErrorInfo
{
  NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
  for (NSUInteger i = 0; i < files.count; i++) {
    if ([files[i] hasPrefix:@"error_report"]) {
      [[NSFileManager defaultManager] removeItemAtPath:[directoryPath stringByAppendingPathComponent:files[i]] error:nil];
    }
  }
}

#pragma mark - disk operations

+ (void)saveErrorInfoToDisk:(NSDictionary<NSString *, id> *)errorInfo
{
  [errorInfo writeToFile:[self pathToErrorInfoFile]
              atomically:YES];
  }

+ (NSString *)pathToErrorInfoFile
{
  NSString *timestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
  return [directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"error_report_%@.plist",timestamp]];
}
@end
