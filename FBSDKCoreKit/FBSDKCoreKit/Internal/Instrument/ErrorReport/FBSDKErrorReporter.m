/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorReporter.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsProtocol.h"

#define FBSDK_MAX_ERROR_REPORT_LOGS 1000

@implementation FBSDKErrorReporter

static NSString *ErrorReportStorageDirName = @"instrument/";

NSString *const kFBSDKErrorCode = @"error_code";
NSString *const kFBSDKErrorDomain = @"domain";
NSString *const kFBSDKErrorTimestamp = @"timestamp";

# pragma mark - Public Methods

- (instancetype)init
{
  return [self initWithGraphRequestFactory:[FBSDKGraphRequestFactory new]
                               fileManager:NSFileManager.defaultManager
                                  settings:FBSDKSettings.sharedSettings
                         fileDataExtractor:NSData.class];
}

- (instancetype)initWithGraphRequestFactory:(nonnull id<FBSDKGraphRequestFactory>)graphRequestFactory
                                fileManager:(nonnull id<FBSDKFileManaging>)fileManager
                                   settings:(nonnull id<FBSDKSettings>)settings
                          fileDataExtractor:(nonnull Class<FBSDKFileDataExtracting>)dataExtractor
{
  if ((self = [super init])) {
    _graphRequestFactory = graphRequestFactory;
    _fileManager = fileManager;
    _settings = settings;
    _dataExtractor = dataExtractor;
    _directoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:ErrorReportStorageDirName];
  }

  return self;
}

+ (instancetype)shared
{
  static FBSDKErrorReporter *_sharedInstance;
  static dispatch_once_t nonce;
  dispatch_once(&nonce, ^{
    _sharedInstance = [self new];
  });
  return _sharedInstance;
}

- (void)enable
{
  [self createErrorDirectoryIfNeeded];
  if (![self.settings isDataProcessingRestricted]) {
    [self uploadErrors];
  }
  self.isEnabled = YES;
}

+ (void)saveError:(NSInteger)errorCode
      errorDomain:(NSErrorDomain)errorDomain
          message:(nullable NSString *)message
{
  [[FBSDKErrorReporter new] saveError:errorCode
                          errorDomain:errorDomain
                              message:message];
}

- (void)saveError:(NSInteger)errorCode
      errorDomain:(NSErrorDomain)errorDomain
          message:(nullable NSString *)message
{
  if (self.isEnabled) {
    NSString *timestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
    [self _saveErrorInfoToDisk:@{
       kFBSDKErrorCode : @(errorCode),
       kFBSDKErrorDomain : errorDomain,
       kFBSDKErrorTimestamp : timestamp,
     }];
  }
}

#pragma mark - Private Methods

- (void)createErrorDirectoryIfNeeded
{
  if (![self.fileManager fb_fileExistsAtPath:self.directoryPath]) {
    if (![self.fileManager fb_createDirectoryAtPath:self.directoryPath
                        withIntermediateDirectories:NO
                                         attributes:NULL
                                              error:NULL]) {
      NSString *msg = [NSString stringWithFormat:@"Failed to create library at %@", self.directoryPath];
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorInformational logEntry:msg];
    }
  }
}

- (void)uploadErrors
{
  NSArray<NSDictionary<NSString *, id> *> *errorReports = [self loadErrorReports];
  if (errorReports.count == 0) {
    return [self _clearErrorInfo];
  }
  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:errorReports options:0 error:nil];
  if (!jsonData) {
    return;
  }
  NSString *errorData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/instruments", self.settings.appID]
                                                                                 parameters:@{@"error_reports" : errorData ?: @""}
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST];

  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (!error && [result isKindOfClass:[NSDictionary<NSString *, id> class]] && result[@"success"]) {
      [self _clearErrorInfo];
    }
  }];
}

- (NSArray<NSDictionary<NSString *, id> *> *)loadErrorReports
{
  NSMutableArray<NSDictionary<NSString *, id> *> *errorReportArr = [NSMutableArray array];
  NSArray<NSString *> *fileNames = [self.fileManager fb_contentsOfDirectoryAtPath:self.directoryPath error:NULL];
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id _Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
    NSString *str = (NSString *)evaluatedObject;
    return [str hasPrefix:@"error_report_"] && [str hasSuffix:@".json"];
  }];
  fileNames = [fileNames filteredArrayUsingPredicate:predicate];
  fileNames = [fileNames sortedArrayUsingComparator:^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
    return [obj2 compare:obj1];
  }];
  if (fileNames.count > 0) {
    fileNames = [fileNames subarrayWithRange:NSMakeRange(0, MIN(fileNames.count, FBSDK_MAX_ERROR_REPORT_LOGS))];
    for (NSUInteger i = 0; i < fileNames.count; i++) {
      NSString *path = [self.directoryPath stringByAppendingPathComponent:[FBSDKTypeUtility array:fileNames objectAtIndex:i]];
      NSData *data = [self.dataExtractor fb_dataWithContentsOfFile:path
                                                           options:NSDataReadingMappedIfSafe
                                                             error:nil];
      if (data) {
        NSDictionary<NSString *, id> *errorReport = [FBSDKTypeUtility JSONObjectWithData:data
                                                                                 options:0
                                                                                   error:nil];
        if (errorReport) {
          [FBSDKTypeUtility array:errorReportArr addObject:errorReport];
        }
      }
    }
  }
  return [errorReportArr copy];
}

- (void)_clearErrorInfo
{
  NSArray<NSString *> *files = [self.fileManager fb_contentsOfDirectoryAtPath:self.directoryPath error:nil];
  for (NSString *file in files) {
    if ([file hasPrefix:@"error_report"]) {
      NSString *path = [self.directoryPath stringByAppendingPathComponent:file];
      [self.fileManager fb_removeItemAtPath:path error:nil];
    }
  }
}

- (void)_saveErrorInfoToDisk:(NSDictionary<NSString *, id> *)errorInfo
{
  if (errorInfo.count > 0) {
    NSData *data = [FBSDKTypeUtility dataWithJSONObject:errorInfo options:0 error:nil];
    [data writeToFile:[self _pathToErrorInfoFile]
           atomically:YES];
  }
}

- (NSString *)_pathToErrorInfoFile
{
  NSString *timestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
  return [self.directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"error_report_%@.json", timestamp]];
}

#if DEBUG

- (void)reset
{
  _isEnabled = NO;
}

#endif

@end
