/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingVideoUploader.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

#import "FBSDKVideoUploader.h"
#import "FBSDKVideoUploaderFactory.h"

@interface FBSDKGamingVideoUploader () <FBSDKVideoUploaderDelegate>

@property (nonatomic) NSUInteger totalBytesSent;

@property (nonatomic) id<FBSDKFileHandling> fileHandle;
@property (nonatomic) id<FBSDKFileHandleCreating> fileHandleFactory;
@property (nonatomic) id<FBSDKVideoUploaderCreating> videoUploaderFactory;

@property (nonatomic) NSUInteger totalBytesExpectedToSend;
@property (nullable, nonatomic) FBSDKGamingServiceResultCompletion completionHandler;
@property (nullable, nonatomic) FBSDKGamingServiceProgressHandler progressHandler;

@end

@implementation FBSDKGamingVideoUploader

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
// The goal is to move from:
// ClassWithoutUnderlyingInstance -> ClassRelyingOnUnderlyingInstance -> Instance
+ (FBSDKGamingVideoUploader *)shared
{
  static dispatch_once_t nonce;
  static FBSDKGamingVideoUploader *instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

- (instancetype)init
{
  return [self initWithFileHandleFactory:[FBSDKFileHandleFactory new]
                    videoUploaderFactory:[FBSDKVideoUploaderFactory new]];
}

- (instancetype)initWithFileHandleFactory:(id<FBSDKFileHandleCreating>)fileHandleFactory
                     videoUploaderFactory:(id<FBSDKVideoUploaderCreating>)videoUploaderFactory
{
  if ((self = [super init])) {
    _fileHandleFactory = fileHandleFactory;
    _videoUploaderFactory = videoUploaderFactory;
  }

  return self;
}

+ (FBSDKGamingVideoUploader *)createWithFileHandle:(id<FBSDKFileHandling>)fileHandle
                                  totalBytesToSend:(NSUInteger)totalBytes
                                 completionHandler:(FBSDKGamingServiceResultCompletion _Nonnull)completionHandler
                                   progressHandler:(FBSDKGamingServiceProgressHandler _Nonnull)progressHandler
{
  FBSDKGamingVideoUploader *uploader = [FBSDKGamingVideoUploader new];
  uploader.fileHandle = fileHandle;
  uploader.totalBytesExpectedToSend = totalBytes;
  uploader.completionHandler = completionHandler;
  uploader.progressHandler = progressHandler;

  return uploader;
}

+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
{
  [self.shared uploadVideoWithConfiguration:configuration
                        andResultCompletion:completion];
}

- (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                 andResultCompletion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
{
  [self
   uploadVideoWithConfiguration:configuration
   completion:completion
   andProgressHandler:nil];
}

+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  [self.shared uploadVideoWithConfiguration:configuration
                                 completion:completion
                         andProgressHandler:progressHandler];
}

- (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration *_Nonnull)configuration
                          completion:(FBSDKGamingServiceResultCompletion _Nonnull)completion
                  andProgressHandler:(FBSDKGamingServiceProgressHandler _Nullable)progressHandler
{
  if (FBSDKAccessToken.currentAccessToken == nil) {
    completion(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorAccessTokenRequired
       message:@"A valid access token is required to upload Images"]
    );

    return;
  }

  if (configuration.videoURL == nil) {
    completion(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorInvalidArgument
       message:@"Attempting to upload a nil videoURL"]
    );

    return;
  }

  id<FBSDKFileHandling> const fileHandle =
  [self.fileHandleFactory fileHandleForReadingFromURL:configuration.videoURL
                                                error:nil];

  if ((unsigned long)[fileHandle seekToEndOfFile] == 0) {
    completion(
      false,
      nil,
      [FBSDKError
       errorWithCode:FBSDKErrorInvalidArgument
       message:@"Attempting to upload an empty video file"]
    );

    return;
  }

  const NSUInteger fileSize = (unsigned long)[fileHandle seekToEndOfFile];

  FBSDKGamingVideoUploader *const uploader =
  [FBSDKGamingVideoUploader
   createWithFileHandle:fileHandle
   totalBytesToSend:fileSize
   completionHandler:completion
   progressHandler:progressHandler];

  [FBSDKInternalUtility.sharedUtility registerTransientObject:uploader];

  id<FBSDKVideoUploading> const videoUploader =
  [self.videoUploaderFactory
   createWithVideoName:[configuration.videoURL lastPathComponent]
   videoSize:fileSize
   parameters:@{}
   delegate:uploader];

  [videoUploader start];
}

- (void)safeCompleteWithSuccess:(BOOL)success
                          error:(NSError *)error
                         result:(id)result
{
  NSError *finalError = error;

  if (success == false && error == nil) {
    finalError =
    [FBSDKError
     errorWithCode:FBSDKErrorUnknown
     message:@"Video upload was unsuccessful, but no error was thrown."];
  }

  if (_completionHandler != nil) {
    self.completionHandler(success, result, finalError);
  }

  [FBSDKInternalUtility.sharedUtility unregisterTransientObject:self];
}

- (void)safeProgressWithTotalBytesSent:(NSUInteger)totalBytesSent
{
  if (!_progressHandler) {
    return;
  }

  const NSUInteger bytesSent = totalBytesSent - _totalBytesSent;
  _totalBytesSent = totalBytesSent;

  _progressHandler(bytesSent, _totalBytesSent, _totalBytesExpectedToSend);
}

#pragma mark - FBSDKVideoUploaderDelegate

- (nullable NSData *)videoChunkDataForVideoUploader:(FBSDKVideoUploader *)videoUploader
                                        startOffset:(NSUInteger)startOffset
                                          endOffset:(NSUInteger)endOffset
{
  NSUInteger chunkSize = endOffset - startOffset;
  [_fileHandle seekToFileOffset:startOffset];
  NSData *videoChunkData = [_fileHandle readDataOfLength:chunkSize];
  if (videoChunkData == nil || videoChunkData.length != chunkSize) {
    return nil;
  }

  [self safeProgressWithTotalBytesSent:startOffset];

  return videoChunkData;
}

- (void)   videoUploader:(FBSDKVideoUploader *)videoUploader
  didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  [self safeProgressWithTotalBytesSent:_totalBytesExpectedToSend];

  BOOL serverSuccess = NO;
  id success = results[@"success"];
  if ([success isKindOfClass:NSString.class] || [success isKindOfClass:NSNumber.class]) {
    serverSuccess = [success boolValue];
  }
  [self
   safeCompleteWithSuccess:serverSuccess
   error:nil
   result:@{@"video_id" : results[@"video_id"] ?: @""}];
}

- (void)videoUploader:(FBSDKVideoUploader *)videoUploader
     didFailWithError:(NSError *)error
{
  [self
   safeCompleteWithSuccess:false
   error:error
   result:nil];
}

@end
