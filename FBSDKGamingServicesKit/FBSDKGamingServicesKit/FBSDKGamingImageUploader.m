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

#import "FBSDKGamingImageUploader.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKGamingImageUploaderConfiguration.h"
#import "FBSDKGamingServiceController.h"

@interface FBSDKGamingImageUploader () <FBSDKGraphRequestConnectionDelegate>
{
  FBSDKGamingServiceProgressHandler _progressHandler;
}

@end

@implementation FBSDKGamingImageUploader

- (instancetype)init
{
  return [super init];
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration * _Nonnull)configuration
                andCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  return
  [self
   uploadImageWithConfiguration:configuration
   completionHandler:^(BOOL success, id _Nullable result, NSError * _Nullable error) {
    if (completionHandler) {
      completionHandler(success, error);
    }
  }
   andProgressHandler:nil];
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration * _Nonnull)configuration
          andResultCompletionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
{
  return
  [self
   uploadImageWithConfiguration:configuration
   completionHandler:completionHandler
   andProgressHandler:nil];
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration * _Nonnull)configuration
                   completionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionHandler(false,
                      nil,
                      [FBSDKError
                       errorWithCode:FBSDKErrorAccessTokenRequired
                       message:@"A valid access token is required to upload Images"]);

    return;
  }

  if (configuration.image == nil) {
    completionHandler(false,
                      nil,
                      [FBSDKError
                       errorWithCode:FBSDKErrorInvalidArgument
                       message:@"Attempting to upload a nil image"]);

    return;
  }

  FBSDKGraphRequestConnection *const connection =
  [[FBSDKGraphRequestConnection alloc] init];

  FBSDKGamingImageUploader *const uploader =
  [[FBSDKGamingImageUploader alloc]
   initWithProgressHandler:progressHandler];

  connection.delegate = uploader;
  [FBSDKInternalUtility registerTransientObject:connection.delegate];

  [connection
   addRequest:
   [[FBSDKGraphRequest alloc]
    initWithGraphPath:@"me/photos"
    parameters:@{
      @"caption": configuration.caption ?: @"",
      @"picture": UIImagePNGRepresentation(configuration.image)
    }
    HTTPMethod:FBSDKHTTPMethodPOST]
   completionHandler:^(FBSDKGraphRequestConnection * _Nullable connection, id  _Nullable result, NSError * _Nullable error) {
    [FBSDKInternalUtility unregisterTransientObject:connection.delegate];

    if (error || !result) {
      completionHandler(false,
                        nil,
                        [FBSDKError
                         errorWithCode:FBSDKErrorGraphRequestGraphAPI
                         message:@"Image upload failed"
                         underlyingError:error]);
      return;
    }

    if (!configuration.shouldLaunchMediaDialog) {
      completionHandler(true, result, nil);
      return;
    }

    FBSDKGamingServiceController *const controller =
    [[FBSDKGamingServiceController alloc]
     initWithServiceType:FBSDKGamingServiceTypeMediaAsset
     completionHandler:completionHandler
     pendingResult:result];

    [controller callWithArgument:result[@"id"]];
  }];

  [connection start];
}

- (instancetype)initWithProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if (self = [super init]) {
    _progressHandler = progressHandler;
  }
  return self;
}

#pragma mark - FBSDKGraphRequestConnectionDelegate

- (void)requestConnection:(FBSDKGraphRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  if (!_progressHandler) {
    return;
  }

  _progressHandler(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

@end
