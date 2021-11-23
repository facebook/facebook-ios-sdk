/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingImageUploader.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

@interface FBSDKGamingImageUploader () <FBSDKGraphRequestConnectionDelegate>

@property (nonatomic) FBSDKGamingServiceProgressHandler progressHandler;

@property (nonnull, nonatomic) id<FBSDKGamingServiceControllerCreating> factory;
@property (nonnull, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;

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
  return [self initWithGamingServiceControllerFactory:[FBSDKGamingServiceControllerFactory new]
                        graphRequestConnectionFactory:[FBSDKGraphRequestConnectionFactory new]];
}

- (instancetype)initWithProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if ((self = [self initWithGamingServiceControllerFactory:[FBSDKGamingServiceControllerFactory new]
                             graphRequestConnectionFactory:[FBSDKGraphRequestConnectionFactory new]])) {
    _progressHandler = progressHandler;
  }
  return self;
}

- (instancetype)initWithGamingServiceControllerFactory:(id<FBSDKGamingServiceControllerCreating>)factory
                         graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  if ((self = [super init])) {
    _factory = factory;
    _graphRequestConnectionFactory = graphRequestConnectionFactory;
  }
  return self;
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
{
  [self.shared uploadImageWithConfiguration:configuration
                        andResultCompletion:completion];
}

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
{
  return
  [self
   uploadImageWithConfiguration:configuration
   completion:completion
   andProgressHandler:nil];
}

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  [self.shared uploadImageWithConfiguration:configuration
                                 completion:completion
                         andProgressHandler:progressHandler];
}

- (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completionHandler
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if (FBSDKAccessToken.currentAccessToken == nil) {
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

  id<FBSDKGraphRequestConnecting> const connection =
  [self.graphRequestConnectionFactory createGraphRequestConnection];

  FBSDKGamingImageUploader *const uploader =
  [[FBSDKGamingImageUploader alloc]
   initWithProgressHandler:progressHandler];

  connection.delegate = uploader;
  [FBSDKInternalUtility.sharedUtility registerTransientObject:connection.delegate];

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
     [FBSDKInternalUtility.sharedUtility unregisterTransientObject:graphConnection.delegate];

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
      pendingResult:result
      completion:completionHandler];

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
