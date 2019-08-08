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

#import "FBSDKCrashStorage.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *CrashReportStorageLibName = @"unknown";

NSString *const kFBSDKCallstack = @"callstack";
NSString *const kFBSDKCrashReason = @"crash_reason";
NSString *const kFBSDKCrashTimeStamp = @"crash_time_stamp";

@implementation FBSDKCrashStorage

+ (void)setupWithLibName:(NSString *)libName
{
  CrashReportStorageLibName = libName;
}

+ (void)saveException:(NSException *)exception
{
  if (exception.callStackSymbols && exception.name) {
    NSArray<NSString *> *stackSymbols = [NSArray arrayWithArray:exception.callStackSymbols];
    [self saveCrashInfoToDisk:@{
                                kFBSDKCallstack : stackSymbols,
                                kFBSDKCrashReason : [NSString stringWithFormat: @"NSException: %@", exception.name],
                                kFBSDKCrashTimeStamp: @((int) [[NSDate date] timeIntervalSince1970]),
                                }];
  }
}

+ (void)saveSignal:(int)signal withCallStack:(NSArray<NSString *> *)callStack
{
  if (callStack) {
    NSString *signalDescription = [NSString stringWithCString:strsignal(signal) encoding:NSUTF8StringEncoding] ?: [NSString stringWithFormat:@"SIGNUM(%i)", signal];
    [self saveCrashInfoToDisk:@{
                                kFBSDKCallstack : callStack,
                                kFBSDKCrashReason : signalDescription,
                                kFBSDKCrashTimeStamp: @((int) [[NSDate date] timeIntervalSince1970]),
                                }];
  }
}

+ (NSDictionary<NSString *,id> *)loadCrashInfo
{
  return [NSDictionary dictionaryWithContentsOfFile:[self pathToCrashFile]];
}

+ (void)clearCrashInfo
{
  [[NSFileManager defaultManager] removeItemAtPath:[self pathToCrashFile] error:nil];
}

#pragma mark - disk operations

+ (void)saveCrashInfoToDisk:(NSDictionary<NSString *, id> *)crashInfo
{
  [crashInfo writeToFile:[self pathToCrashFile]
              atomically:YES];
}

+ (void)saveLibData:(NSDictionary<NSString *, NSString *> *)data
{
  if (data){
    [data writeToFile:[self pathToLibDataFile]
           atomically:YES];
  } else {
    [[NSFileManager defaultManager] removeItemAtPath:[self pathToLibDataFile] error:nil];
  }
}

+ (NSDictionary<NSString *, NSString *> *)loadLibData
{
  return [NSDictionary dictionaryWithContentsOfFile:[self pathToLibDataFile]];
}

+ (NSString *)pathToCrashFile
{
  return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"crash_%@.bin",CrashReportStorageLibName]];
}

+ (NSString *)pathToLibDataFile
{
  return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"static_lib_data_%@.bin",CrashReportStorageLibName]];

}

@end
