// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FBSDKJSExceptionHandler.h"

#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKSettings.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

/**
 This is hacky but the alternative is to expose this method as public and it
 does not need to be public.
 */
@interface FBSDKSettings (BetaKit)

- (BOOL)isDataProcessingRestricted;

@end

#define FBSDK_MAX_ERROR_REPORT_LOGS 1000

/**
  @brief The path of the directory for where the above is located.
 */
static NSString *directoryPath = nil;

@implementation FBSDKJSExceptionHandler

#pragma mark - Class methods

/**
  @method

  @brief
  Enables the exceptions at the proper directory and then calls the function that
  will upload the JS Error Reports to the endpoint in the Facebook Servers.
 */
+ (void)enable
{
  NSString *dirPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/instrument"];
  if (!dirPath) {
    return;
  }
  /**
   @brief Check that the file does not already exist at the path/directory.
   */
  if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:NULL error:NULL];
  }

  directoryPath = dirPath;
  [FBSDKJSExceptionHandler uploadError];
}

/**
  @method

  @brief
  Generates an error report in the form of a json file and stores it
  in the local directory specified by directoryPath.

  @param message - The `NSString` exception that arose in the
                  JSContext's exceptionHandler block.
 */
+ (void)saveError:(nullable NSString *)message
{
  if (message.length == 0) {
    return;
  }

  NSString *timestamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
  NSString *fileName = [NSString stringWithFormat:@"js_error_reports_%@.json", timestamp];
  NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];

  NSMutableDictionary<NSString *, id> *errorParams = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:errorParams setObject:@"" forKey:@"domain"];
  [FBSDKTypeUtility dictionary:errorParams setObject:timestamp forKey:@"timestamp"];
  [FBSDKTypeUtility dictionary:errorParams setObject:message forKey:@"error_message"];

  /** @brief Save the error to directoryPath where the JS error report is. */
  if (errorParams.count > 0) {
    /**
      @brief The `dispatch_queue_t` that serves as a semaphore for multi-threading.
     */
    fb_dispatch_on_default_thread(^{
      NSData *data = [FBSDKTypeUtility dataWithJSONObject:errorParams options:0 error:nil];
      if (data) {
        [data writeToFile:filePath atomically:YES];
      }
    });
  }
}

/**
  @method

  @brief
  Uploads the reports of the JS errors to the instruments endpoint.
*/
+ (void)uploadError
{
  if ([FBSDKSettings.sharedSettings isDataProcessingRestricted]) {
    return;
  }

  /** @brief All the reports of the exceptions that arose in the JS. */
  NSArray<NSDictionary<NSString *, id> *> *JSErrorReports = [FBSDKJSExceptionHandler loadErrorReports];
  if ([JSErrorReports count] == 0) {
    return;
  }
  NSData *jsonData = [FBSDKTypeUtility dataWithJSONObject:JSErrorReports options:0 error:nil];
  if (!jsonData) {
    return;
  }

  /** @brief A compact, string file composed of all the error reports from the exceptions. */
  NSString *errorData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

  /** @brief Upload the errorData to the Facebook servers at the Error Report endpoint. */
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/instruments", [[FBSDKSettings sharedSettings] appID]]
                                                                 parameters:@{@"error_reports" : errorData ?: @""} HTTPMethod:FBSDKHTTPMethodPOST];

  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (!error && [result isKindOfClass:[NSDictionary class]] && result[@"success"]) {
      [FBSDKJSExceptionHandler clearCache];
    }
  }];
}

/**
  @method

  @brief
  Retrieve all the JS error reports from their storage in the local temporary directory.

  @return errorReports - The `NSArray<NSDictionary<NSString *, id> *> *` value of the array
                     of dictionaries representing all generated reports from exceptions.
 */
+ (NSArray<NSDictionary<NSString *, id> *> *)loadErrorReports
{
  NSMutableArray<NSDictionary<NSString *, id> *> *errorReports = [NSMutableArray array];
  NSArray<NSString *> *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:NULL];
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL (id _Nullable evaluatedObject, NSDictionary<NSString *, id> *_Nullable bindings) {
    NSString *str = (NSString *)evaluatedObject;
    return [str hasPrefix:@"js_error_reports_"] && [str hasSuffix:@".json"];
  }];
  fileNames = [fileNames filteredArrayUsingPredicate:predicate];
  fileNames = [fileNames sortedArrayUsingComparator:^NSComparisonResult (id _Nonnull obj1, id _Nonnull obj2) {
    return [obj2 compare:obj1];
  }];

  if (fileNames.count > 0) {
    fileNames = [fileNames subarrayWithRange:NSMakeRange(0, MIN(fileNames.count, FBSDK_MAX_ERROR_REPORT_LOGS))];
    for (NSUInteger i = 0; i < fileNames.count; i++) {
      NSData *data = [NSData dataWithContentsOfFile:[directoryPath stringByAppendingPathComponent:[FBSDKTypeUtility array:fileNames objectAtIndex:i]]
                                            options:NSDataReadingMappedIfSafe
                                              error:nil];
      if (data) {
        NSDictionary<NSString *, id> *JSErrorReport = [FBSDKTypeUtility JSONObjectWithData:data
                                                                                   options:0
                                                                                     error:nil];
        if (JSErrorReport) {
          [FBSDKTypeUtility array:errorReports addObject:JSErrorReport];
        }
      }
    }
  }
  return [errorReports copy];
}

/**
  @method

  @brief
  Clearing all the JS Error Reports.
 */
+ (void)clearCache
{
  NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
  for (NSUInteger i = 0; i < files.count; i++) {
    NSString *file = (NSString *)[FBSDKTypeUtility array:files objectAtIndex:i];
    if ([file hasPrefix:@"error_message"]) {
      [[NSFileManager defaultManager] removeItemAtPath:[directoryPath stringByAppendingPathComponent:file] error:nil];
    }
  }
  NSLog(@"The cache of JS Error Reports has been cleared.");
}

@end
