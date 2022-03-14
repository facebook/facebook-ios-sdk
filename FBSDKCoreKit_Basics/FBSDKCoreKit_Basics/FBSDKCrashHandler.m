/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKCrashHandler.h"

#import <UIKit/UIKit.h>

#import <sys/utsname.h>

#import "FBSDKCrashObserving.h"
#import "FBSDKFileDataExtracting.h"
#import "FBSDKFileManaging.h"
#import "FBSDKLibAnalyzer.h"
#import "FBSDKTypeUtility.h"
#import "NSBundle+InfoDictionaryProviding.h"

#define FBSDK_MAX_CRASH_LOGS 5
#define FBSDK_CRASH_PATH_NAME @"instrument"
#ifndef FBSDK_VERSION_STRING
 #define FBSDK_VERSION_STRING @"13.1.0"
#endif

static NSUncaughtExceptionHandler *previousExceptionHandler = NULL;
static NSString *mappingTableIdentifier = NULL;
static NSString *directoryPath;

NSString *const kFBSDKAppVersion = @"app_version";
NSString *const kFBSDKCallstack = @"callstack";
NSString *const kFBSDKCrashReason = @"reason";
NSString *const kFBSDKCrashTimestamp = @"timestamp";
NSString *const kFBSDKDeviceModel = @"device_model";
NSString *const kFBSDKDeviceOSVersion = @"device_os_version";

NSString *const kFBSDKMapingTable = @"mapping_table";
NSString *const kFBSDKMappingTableIdentifier = @"mapping_table_identifier";

@interface FBSDKCrashHandler ()

@property (nonatomic) BOOL isTurnedOn;
@property (nonatomic) id<FBSDKFileManaging> fileManager;
@property (nonatomic, strong) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nonatomic) id<FBSDKInfoDictionaryProviding> bundle;
@property (nonatomic) NSHashTable<id<FBSDKCrashObserving>> *observers;
@property (nonatomic) NSArray<NSDictionary<NSString *, id> *> *processedCrashLogs;

@end

@implementation FBSDKCrashHandler

- (instancetype)initWithFileManager:(id<FBSDKFileManaging>)fileManager
                             bundle:(id<FBSDKInfoDictionaryProviding>)bundle
                  fileDataExtractor:(nonnull Class<FBSDKFileDataExtracting>)dataExtractor
{
  if ((self = [super init])) {
    _observers = [NSHashTable new];
    _isTurnedOn = YES;
    _fileManager = fileManager;
    _bundle = bundle;
    _dataExtractor = dataExtractor;

    NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FBSDK_CRASH_PATH_NAME];
    if (![_fileManager fileExistsAtPath:dirPath]) {
      [_fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL];
    }
    directoryPath = dirPath;
    NSString *identifier = [[NSUUID UUID] UUIDString];
    mappingTableIdentifier = [identifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
  }
  return self;
}

+ (instancetype)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [[self alloc] initWithFileManager:NSFileManager.defaultManager
                                          bundle:NSBundle.mainBundle
                               fileDataExtractor:NSData.class
    ];
  });
  return instance;
}

#pragma mark - Public API

+ (NSString *)getFBSDKVersion
{
  return FBSDK_VERSION_STRING;
}

+ (void)disable
{
  [FBSDKCrashHandler.shared disable];
}

- (void)disable
{
  self.isTurnedOn = NO;
  [FBSDKCrashHandler.shared _uninstallExceptionsHandler];
  self.observers = nil;
}

+ (void)addObserver:(id<FBSDKCrashObserving>)observer
{
  [FBSDKCrashHandler.shared addObserver:observer];
}

- (void)addObserver:(id<FBSDKCrashObserving>)observer
{
  if (!self.isTurnedOn || ![self _isSafeToGenerateMapping]) {
    return;
  }
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [FBSDKCrashHandler.shared _installExceptionsHandler];
    _processedCrashLogs = [self _getProcessedCrashLogs];
  });
  @synchronized(_observers) {
    if (![self.observers containsObject:observer]) {
      [self.observers addObject:observer];
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [self _generateMethodMapping:observer];
      });
      [self _sendCrashLogs];
    }
  }
}

+ (void)removeObserver:(id<FBSDKCrashObserving>)observer
{
  [FBSDKCrashHandler.shared removeObserver:observer];
}

- (void)removeObserver:(id<FBSDKCrashObserving>)observer
{
  @synchronized(_observers) {
    if ([self.observers containsObject:observer]) {
      [self.observers removeObject:observer];
      if (self.observers.count == 0) {
        [FBSDKCrashHandler.shared _uninstallExceptionsHandler];
      }
    }
  }
}

+ (void)clearCrashReportFiles
{
  [FBSDKCrashHandler.shared clearCrashReportFiles];
}

- (void)clearCrashReportFiles
{
  NSArray<NSString *> *files = [self.fileManager contentsOfDirectoryAtPath:directoryPath error:nil];

  for (NSUInteger i = 0; i < files.count; i++) {
    // remove all crash related files except for the current mapping table
    if ([[FBSDKTypeUtility array:files objectAtIndex:i] hasPrefix:@"crash_"] && ![[FBSDKTypeUtility array:files objectAtIndex:i] containsString:mappingTableIdentifier]) {
      [self.fileManager removeItemAtPath:[directoryPath stringByAppendingPathComponent:[FBSDKTypeUtility array:files objectAtIndex:i]] error:nil];
    }
  }
}

# pragma mark - Handler

- (void)_installExceptionsHandler
{
  NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();

  if (currentHandler != FBSDKExceptionHandler) {
    previousExceptionHandler = currentHandler;
    NSSetUncaughtExceptionHandler(&FBSDKExceptionHandler);
  }
}

- (void)_uninstallExceptionsHandler
{
  NSSetUncaughtExceptionHandler(previousExceptionHandler);
  previousExceptionHandler = nil;
}

static void FBSDKExceptionHandler(NSException *exception)
{
  [FBSDKCrashHandler.shared _saveException:exception];
  if (previousExceptionHandler) {
    previousExceptionHandler(exception);
  }
}

#pragma mark - Storage & Process

- (void)_saveException:(NSException *)exception
{
  if (exception.callStackSymbols && exception.name) {
    NSArray<NSString *> *stackSymbols = [NSArray arrayWithArray:exception.callStackSymbols];
    [self _saveCrashLog:@{
       kFBSDKCallstack : stackSymbols,
       kFBSDKCrashReason : exception.name,
     }];
  }
}

- (nullable NSArray<NSDictionary<NSString *, id> *> *)_getProcessedCrashLogs
{
  NSArray<NSDictionary<NSString *, id> *> *crashLogs = [self _loadCrashLogs];
  if (0 == crashLogs.count) {
    [self clearCrashReportFiles];
    return nil;
  }
  NSMutableArray<NSDictionary<NSString *, id> *> *processedCrashLogs = [NSMutableArray array];

  for (NSDictionary<NSString *, id> *crashLog in crashLogs) {
    NSArray<NSString *> *callstack = crashLog[kFBSDKCallstack];
    NSData *data = [self _loadLibData:crashLog];
    if (!data) {
      continue;
    }
    NSDictionary<NSString *, id> *methodMapping = [FBSDKTypeUtility JSONObjectWithData:data
                                                                               options:kNilOptions
                                                                                 error:nil];
    NSArray<NSString *> *symbolicatedCallstack = [FBSDKLibAnalyzer symbolicateCallstack:callstack methodMapping:methodMapping];
    NSMutableDictionary<NSString *, id> *symbolicatedCrashLog = [NSMutableDictionary dictionaryWithDictionary:crashLog];
    if (symbolicatedCallstack) {
      [FBSDKTypeUtility dictionary:symbolicatedCrashLog setObject:symbolicatedCallstack forKey:kFBSDKCallstack];
      [symbolicatedCrashLog removeObjectForKey:kFBSDKMappingTableIdentifier];
      [FBSDKTypeUtility array:processedCrashLogs addObject:symbolicatedCrashLog];
    }
  }
  return processedCrashLogs;
}

- (NSArray<NSDictionary<NSString *, id> *> *)_loadCrashLogs
{
  NSArray<NSString *> *files = [self.fileManager contentsOfDirectoryAtPath:directoryPath error:NULL];
  NSArray<NSString *> *fileNames = [[self _getCrashLogFileNames:files] sortedArrayUsingComparator:^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
    return [obj2 compare:obj1];
  }];
  NSMutableArray<NSDictionary<NSString *, id> *> *crashLogArray = [NSMutableArray array];

  for (NSUInteger i = 0; i < MIN(fileNames.count, FBSDK_MAX_CRASH_LOGS); i++) {
    NSData *data = [self _loadCrashLog:[FBSDKTypeUtility array:fileNames objectAtIndex:i]];
    if (!data) {
      continue;
    }
    NSDictionary<NSString *, id> *crashLog = [FBSDKTypeUtility JSONObjectWithData:data
                                                                          options:kNilOptions
                                                                            error:nil];
    if (crashLog) {
      [FBSDKTypeUtility array:crashLogArray addObject:crashLog];
    }
  }
  return [crashLogArray copy];
}

- (nullable NSData *)_loadCrashLog:(NSString *)fileName
{
  return [self.dataExtractor dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:fileName] options:NSDataReadingMappedIfSafe error:nil];
}

- (NSArray<NSString *> *)_getCrashLogFileNames:(NSArray<NSString *> *)files
{
  NSMutableArray<NSString *> *fileNames = [NSMutableArray array];

  for (NSString *fileName in files) {
    if ([fileName hasPrefix:@"crash_log_"] && [fileName hasSuffix:@".json"]) {
      [FBSDKTypeUtility array:fileNames addObject:fileName];
    }
  }

  return fileNames;
}

- (void)_saveCrashLog:(NSDictionary<NSString *, id> *)crashLog
{
  NSMutableDictionary<NSString *, id> *completeCrashLog = [NSMutableDictionary dictionaryWithDictionary:crashLog];
  NSString *currentTimestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];

  [FBSDKTypeUtility dictionary:completeCrashLog setObject:currentTimestamp forKey:kFBSDKCrashTimestamp];
  [FBSDKTypeUtility dictionary:completeCrashLog setObject:mappingTableIdentifier forKey:kFBSDKMappingTableIdentifier];

  NSString *version = [self.bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  NSString *build = [self.bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
  [FBSDKTypeUtility dictionary:completeCrashLog setObject:[NSString stringWithFormat:@"%@(%@)", version, build] forKey:kFBSDKAppVersion];

  struct utsname systemInfo;
  uname(&systemInfo);
  [FBSDKTypeUtility dictionary:completeCrashLog setObject:@(systemInfo.machine) forKey:kFBSDKDeviceModel];

  [FBSDKTypeUtility dictionary:completeCrashLog setObject:UIDevice.currentDevice.systemVersion forKey:kFBSDKDeviceOSVersion];

  NSData *data = [FBSDKTypeUtility dataWithJSONObject:completeCrashLog options:0 error:nil];

  [data writeToFile:[self _getPathToCrashFile:currentTimestamp]
         atomically:YES];
}

- (void)_sendCrashLogs
{
  for (id<FBSDKCrashObserving> observer in _observers) {
    if (observer) {
      NSArray<NSDictionary<NSString *, id> *> *filteredCrashLogs = [self _filterCrashLogs:observer.prefixes processedCrashLogs:_processedCrashLogs];
      [observer didReceiveCrashLogs:filteredCrashLogs];
    }
  }
}

+ (NSArray<NSDictionary<NSString *, id> *> *)_filterCrashLogs:(NSArray<NSString *> *)prefixList
                                           processedCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs
{
  return [FBSDKCrashHandler.shared _filterCrashLogs:prefixList processedCrashLogs:processedCrashLogs];
}

- (NSArray<NSDictionary<NSString *, id> *> *)_filterCrashLogs:(NSArray<NSString *> *)prefixList
                                           processedCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs
{
  NSMutableArray<NSDictionary<NSString *, id> *> *crashLogs = [NSMutableArray array];
  for (NSDictionary<NSString *, id> *crashLog in processedCrashLogs) {
    NSArray<NSString *> *callstack = crashLog[kFBSDKCallstack];
    if ([self _callstack:callstack containsPrefix:prefixList]) {
      [FBSDKTypeUtility array:crashLogs addObject:crashLog];
    }
  }
  return crashLogs;
}

+ (BOOL)_callstack:(NSArray<NSString *> *)callstack
    containsPrefix:(NSArray<NSString *> *)prefixList
{
  return [FBSDKCrashHandler.shared _callstack:callstack containsPrefix:prefixList];
}

- (BOOL)_callstack:(NSArray<NSString *> *)callstack
    containsPrefix:(NSArray<NSString *> *)prefixList
{
  NSString *callStackString = [callstack componentsJoinedByString:@""];
  for (NSString *prefix in prefixList) {
    if ([callStackString containsString:prefix]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark - Method Mapping

+ (void)_generateMethodMapping:(id<FBSDKCrashObserving>)observer
{
  [FBSDKCrashHandler.shared _generateMethodMapping:observer];
}

- (void)_generateMethodMapping:(id<FBSDKCrashObserving>)observer
{
  if (observer.prefixes.count == 0) {
    return;
  }
  [NSUserDefaults.standardUserDefaults setObject:mappingTableIdentifier forKey:kFBSDKMappingTableIdentifier];
  NSDictionary<NSString *, NSString *> *methodMapping = [FBSDKLibAnalyzer getMethodsTable:observer.prefixes
                                                                               frameworks:observer.frameworks];
  if (methodMapping.count > 0) {
    NSData *data = [FBSDKTypeUtility dataWithJSONObject:methodMapping options:0 error:nil];
    [data writeToFile:[self _getPathToLibDataFile:mappingTableIdentifier]
           atomically:YES];
  }
}

+ (nullable NSData *)_loadLibData:(NSDictionary<NSString *, id> *)crashLog
{
  return [FBSDKCrashHandler.shared _loadLibData:crashLog];
}

- (nullable NSData *)_loadLibData:(NSDictionary<NSString *, id> *)crashLog
{
  NSString *identifier = [FBSDKTypeUtility dictionary:crashLog objectForKey:kFBSDKMappingTableIdentifier ofType:NSObject.class];
  return [self.dataExtractor dataWithContentsOfFile:[self _getPathToLibDataFile:identifier] options:NSDataReadingMappedIfSafe error:nil];
}

+ (NSString *)_getPathToCrashFile:(NSString *)timestamp
{
  return [FBSDKCrashHandler.shared _getPathToCrashFile:timestamp];
}

- (NSString *)_getPathToCrashFile:(NSString *)timestamp
{
  return [directoryPath stringByAppendingPathComponent:
          [NSString stringWithFormat:@"crash_log_%@.json", timestamp]];
}

+ (NSString *)_getPathToLibDataFile:(NSString *)identifier
{
  return [FBSDKCrashHandler.shared _getPathToLibDataFile:identifier];
}

- (NSString *)_getPathToLibDataFile:(NSString *)identifier
{
  return [directoryPath stringByAppendingPathComponent:
          [NSString stringWithFormat:@"crash_lib_data_%@.json", identifier]];
}

+ (BOOL)_isSafeToGenerateMapping
{
  return [FBSDKCrashHandler.shared _isSafeToGenerateMapping];
}

- (BOOL)_isSafeToGenerateMapping
{
#if TARGET_OS_SIMULATOR
  return YES;
#else
  NSString *identifier = [NSUserDefaults.standardUserDefaults objectForKey:kFBSDKMappingTableIdentifier];
  // first app start
  if (!identifier) {
    return YES;
  }

  return [self.fileManager fileExistsAtPath:[self _getPathToLibDataFile:identifier]];
#endif
}

@end
