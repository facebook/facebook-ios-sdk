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

#import "FBSDKCoreKitInternalImport.h"
#import "FBSDKGamingImageUploaderConfiguration.h"
#import "FBSDKGamingServiceControllerCreating.h"
#import "FBSDKGamingServiceControllerFactory.h"

@interface FBSDKGamingImageUploader () <FBSDKGraphRequestConnectionDelegate>
{
  FBSDKGamingServiceProgressHandler _progressHandler;
}

@property (nonnull, nonatomic) id<FBSDKGamingServiceControllerCreating> factory;

@end

@implementation FBSDKGamingImageUploader

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
+ (FBSDKGamingImageUploader *)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

- (instancetype)init
{
  return [self initWithGamingServiceControllerFactory:[FBSDKGamingServiceControllerFactory new]];
}

- (instancetype)initWithProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if ((self = [self initWithGamingServiceControllerFactory:[FBSDKGamingServiceControllerFactory new]])) {
    _progressHandler = progressHandler;
  }
  return self;
}

- (instancetype)initWithGamingServiceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory
{
  if ((self = [super init])) {
    _factory = factory;
  }
  return self;
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
          andResultCompletionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
{
  [self.shared uploadImageWithConfiguration:configuration
                 andResultCompletionHandler:completionHandler];
}

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
          andResultCompletionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
{
  return
  [self
   uploadImageWithConfiguration:configuration
   completionHandler:completionHandler
   andProgressHandler:nil];
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                   completionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  [self.shared uploadImageWithConfiguration:configuration
                          completionHandler:completionHandler
                         andProgressHandler:progressHandler];
}

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                   completionHandler:(FBSDKGamingServiceResultCompletionHandler _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionHandler(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorAccessTokenRequired
       message:@"A valid access token is required to upload Images"]
    );

    return;
  }

  if (configuration.image == nil) {
    completionHandler(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorInvalidArgument
       message:@"Attempting to upload a nil image"]
    );

    return;
  }

  FBSDKGraphRequestConnection *const connection =
  [FBSDKGraphRequestConnection new];

  FBSDKGamingImageUploader *const uploader =
  [[FBSDKGamingImageUploader alloc]
   initWithProgressHandler:progressHandler];

  connection.delegate = uploader;
  [FBSDKInternalUtility registerTransientObject:connection.delegate];

  __weak typeof(self) weakSelf = self;
  [connection
   addRequest:
   [[FBSDKGraphRequest alloc]
    initWithGraphPath:@"me/photos"
    parameters:@{
      @"caption" : configuration.caption ?: @"",
      @"picture" : UIImagePNGRepresentation(configuration.image)
    }
    HTTPMethod:FBSDKHTTPMethodPOST]
   completion:^(id<FBSDKGraphRequestConnecting> _Nullable graphConnection, id _Nullable result, NSError *_Nullable error) {
     [FBSDKInternalUtility unregisterTransientObject:graphConnection.delegate];

     if (error || !result) {
       completionHandler(
         false,
         nil,
         [FBSDKError
          errorWithCode:FBSDKErrorGraphRequestGraphAPI
          message:@"Image upload failed"
          underlyingError:error]
       );
       return;
     }

     if (!configuration.shouldLaunchMediaDialog) {
       completionHandler(true, result, nil);
       return;
     }

     id<FBSDKGamingServiceController> const controller =
     [weakSelf.factory
      createWithServiceType:FBSDKGamingServiceTypeMediaAsset
      completionHandler:completionHandler
      pendingResult:result];

     [controller callWithArgument:result[@"id"]];
   }];

  [connection start];
}

#pragma mark - FBSDKGraphRequestConnectionDelegate

- (void)  requestConnection:(FBSDKGraphRequestConnection *)connection
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
