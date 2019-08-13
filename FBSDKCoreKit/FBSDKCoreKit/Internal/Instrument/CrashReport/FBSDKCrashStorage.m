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

#import "FBSDKLibAnalyzer.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"

static NSString *mappingTableSavedTime = NULL;
static NSString *directoryPath;

NSString *const kFBSDKCallstack = @"callstack";
NSString *const kFBSDKCrashReason = @"reason";
NSString *const kFBSDKCrashTimestamp = @"timestamp";

NSString *const kFBSDKMapingTableTimestamp = @"mapping_table_timestamp";

@implementation FBSDKCrashStorage

+ (void)initialize
{
  NSString *dirPath = [NSTemporaryDirectory() stringByAppendingString:@"instrument/"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
    if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL]) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational formatString:@"Failed to create library at %@", dirPath];
    }
  }
  directoryPath = dirPath;
  mappingTableSavedTime = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
}

+ (void)saveException:(NSException *)exception
{
  if (exception.callStackSymbols && exception.name) {
    NSArray<NSString *> *stackSymbols = [NSArray arrayWithArray:exception.callStackSymbols];
    [self saveCrashLog:@{
                         kFBSDKCallstack : stackSymbols,
                         kFBSDKCrashReason : [NSString stringWithFormat: @"NSException: %@", exception.name],
                         }];
  }
}

+ (void)saveSignal:(int)signal withCallStack:(NSArray<NSString *> *)callStack
{
  if (callStack) {
    NSString *signalDescription = [NSString stringWithCString:strsignal(signal) encoding:NSUTF8StringEncoding] ?: [NSString stringWithFormat:@"SIGNUM(%i)", signal];
    [self saveCrashLog:@{
                         kFBSDKCallstack : callStack,
                         kFBSDKCrashReason : signalDescription,
                         }];
  }
}

+ (NSArray<NSDictionary<NSString *, id> *> *)getProcessedCrashLogs
{
  NSArray<NSDictionary<NSString *, id> *> *crashLogs = [self loadCrashLogs];
  NSMutableArray<NSDictionary<NSString *, id> *> *processedCrashLogs = [NSMutableArray array];

  for (NSDictionary<NSString *, id> *crashLog in crashLogs) {
    NSArray<NSString *> *callstack = crashLog[kFBSDKCallstack];
    NSDictionary<NSString *, id> *methodMapping = [self loadLibData:crashLog];
    NSArray<NSString *> *symbolicatedCallstack = [FBSDKLibAnalyzer symbolicateCallstack:callstack methodMapping:methodMapping];
    NSMutableDictionary<NSString *, id> *symbolicatedCrashLog = [NSMutableDictionary dictionaryWithDictionary:crashLog];
    if (symbolicatedCallstack) {
      [symbolicatedCrashLog setObject:symbolicatedCallstack forKey:kFBSDKCallstack];
      [processedCrashLogs addObject:symbolicatedCrashLog];
    }
  }
  return processedCrashLogs;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)loadCrashLogs
{
  NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:NULL];
  NSArray<NSString *> *fileNames = [self getCrashLogFileNames:files];
  NSMutableArray<NSDictionary<NSString *, id> *> *crashLogArray = [NSMutableArray array];

  for (NSUInteger i = 0; i < fileNames.count; i++) {
    NSDictionary<NSString *, id> *crashLog = [FBSDKCrashStorage loadCrashLog:fileNames[i]];
    [crashLogArray addObject:crashLog];
  }
  return [crashLogArray copy];
}

+ (NSDictionary<NSString *,id> *)loadCrashLog:(NSString *)fileName
{
  return [NSDictionary dictionaryWithContentsOfFile:[directoryPath stringByAppendingPathComponent:fileName]];
}

+ (void)clearCrashReportFiles:(nullable NSString*)timestamp
{
  if (!timestamp) {
    NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];

    for (NSUInteger i = 0; i < files.count; i++) {
      if ([files[i] hasPrefix:@"crash_"]) {
        [[NSFileManager defaultManager] removeItemAtPath:[directoryPath stringByAppendingPathComponent:files[i]] error:nil];
      }
    }
  } else {
    [[NSFileManager defaultManager] removeItemAtPath:[self getPathToCrashFile:timestamp] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[self getPathToLibDataFile:timestamp] error:nil];
  }
}

+ (NSArray<NSString *> *)getCrashLogFileNames:(NSArray<NSString *> *)files
{
  NSMutableArray<NSString *> *fileNames = [NSMutableArray array];

  for (NSString *fileName in files) {
    if ([fileName hasPrefix:@"crash_log_"] && [fileName hasSuffix:@".json"]) {
      [fileNames addObject:fileName];
    }
  }

  return fileNames;
}

#pragma mark - disk operations

+ (void)saveCrashLog:(NSDictionary<NSString *, id> *)crashLog
{
  NSMutableDictionary<NSString *, id> *crashLogWithTimestamp = [NSMutableDictionary dictionaryWithDictionary:crashLog];
  NSString *currentTimestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
  [crashLogWithTimestamp setObject:currentTimestamp forKey:kFBSDKCrashTimestamp];
  [crashLogWithTimestamp setObject:mappingTableSavedTime forKey:kFBSDKMapingTableTimestamp];

  [crashLogWithTimestamp writeToFile:[self getPathToCrashFile:mappingTableSavedTime]
                          atomically:YES];
}

+ (void)generateMethodMapping
{
  NSDictionary<NSString *, NSString *> *methodMapping = [FBSDKLibAnalyzer getMethodsTable];
  if (methodMapping){
    [methodMapping writeToFile:[self getPathToLibDataFile:mappingTableSavedTime]
                    atomically:YES];
  }
}

+ (NSDictionary<NSString *, id> *)loadLibData:(NSDictionary<NSString *, id> *)crashLog
{
  NSString *timestamp = [crashLog objectForKey:kFBSDKMapingTableTimestamp];
  return [NSDictionary dictionaryWithContentsOfFile:[self getPathToLibDataFile:timestamp]];
}

+ (NSString *)getPathToCrashFile:(NSString *)timestamp
{
  return [directoryPath stringByAppendingPathComponent:
          [NSString stringWithFormat:@"crash_log_%@.json", timestamp]];
}

+ (NSString *)getPathToLibDataFile:(NSString *)timestamp
{
  return [directoryPath stringByAppendingPathComponent:
          [NSString stringWithFormat:@"crash_lib_data_%@.json", timestamp]];

}

@end
