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

#import "FBSDKURLSessionTask+Internal.h"

#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"

@implementation FBSDKURLSessionTask(Internal)

#pragma mark - Logging and Completion

+ (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                      error:(NSError *)error
{
  if (error) {
    NSString *logEntry = [NSString
                          stringWithFormat:@"FBSDKURLSessionTask <#%lu>:\n  Error: '%@'\n%@\n",
                          (unsigned long)[FBSDKLogger generateSerialNumber],
                          error.localizedDescription,
                          error.userInfo];

    [FBSDKURLSessionTask logMessage:logEntry];
  }

  [FBSDKURLSessionTask invokeHandler:handler error:error response:nil responseData:nil];
}

+ (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                   response:(NSURLResponse *)response
               responseData:(NSData *)responseData
           requestStartTime:(uint64_t)requestStartTime
{
  // Basic FBSDKURLSessionTask logging just prints out the URL.  FBSDKGraphRequest logging provides more details.
  NSString *mimeType = response.MIMEType;
  NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBSDKURLSessionTask <#%lu>:\n  Duration: %llu msec\nResponse Size: %lu kB\n  MIME type: %@\n",
                                      (unsigned long)[FBSDKLogger generateSerialNumber],
                                      [FBSDKInternalUtility currentTimeInMilliseconds] - requestStartTime,
                                      (unsigned long)responseData.length / 1024,
                                      mimeType];

  if ([mimeType isEqualToString:@"text/javascript"]) {
    NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
  }

  [FBSDKURLSessionTask logMessage:mutableLogEntry];

  [FBSDKURLSessionTask invokeHandler:handler error:nil response:response responseData:responseData];
}

+ (void)invokeHandler:(FBSDKURLSessionTaskBlock)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData
{
  if (handler != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      handler(responseData, response, error);
    });
  }
}

+ (void)logMessage:(NSString *)message
{
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorNetworkRequests formatString:@"%@", message];
}

+ (void)taskDidCompleteWithResponse:(NSURLResponse *)response
                               data:(NSData *)data
                   requestStartTime:(uint64_t)requestStartTime
                            handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    [FBSDKURLSessionTask logAndInvokeHandler:handler
                                    response:response
                                responseData:data
                            requestStartTime:requestStartTime];
  } @finally {}
}

+ (void)taskDidCompleteWithError:(NSError *)error
                         handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorSecureConnectionFailed) {
      NSOperatingSystemVersion iOS9Version = { .majorVersion = 9, .minorVersion = 0, .patchVersion = 0 };
      if ([FBSDKInternalUtility isOSRunTimeVersionAtLeast:iOS9Version]) {
        [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                               logEntry:@"WARNING: FBSDK secure network request failed. Please verify you have configured your "
         "app for Application Transport Security compatibility described at https://developers.facebook.com/docs/ios/ios9"];
      }
    }
    [FBSDKURLSessionTask logAndInvokeHandler:handler error:error];
  } @finally {}
}

@end
