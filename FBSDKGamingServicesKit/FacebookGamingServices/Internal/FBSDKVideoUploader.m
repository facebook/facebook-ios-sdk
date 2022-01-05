/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKVideoUploader.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

#define FBSDK_GAMING_RESULT_COMPLETION_GESTURE_KEY @"completionGesture"
#define FBSDK_GAMING_RESULT_COMPLETION_GESTURE_VALUE_POST @"post"
#define FBSDK_GAMING_VIDEO_END_OFFSET @"end_offset"
#define FBSDK_GAMING_VIDEO_FILE_CHUNK @"video_file_chunk"
#define FBSDK_GAMING_VIDEO_ID @"video_id"
#define FBSDK_GAMING_VIDEO_SIZE @"file_size"
#define FBSDK_GAMING_VIDEO_START_OFFSET @"start_offset"
#define FBSDK_GAMING_VIDEO_UPLOAD_PHASE @"upload_phase"
#define FBSDK_GAMING_VIDEO_UPLOAD_PHASE_FINISH @"finish"
#define FBSDK_GAMING_VIDEO_UPLOAD_PHASE_START @"start"
#define FBSDK_GAMING_VIDEO_UPLOAD_PHASE_TRANSFER @"transfer"
#define FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID @"upload_session_id"
#define FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS @"success"

static NSErrorDomain const FBSDKGamingVideoUploadErrorDomain = @"com.facebook.sdk.gaming.videoupload";

static NSString *const FBSDKVideoUploaderDefaultGraphNode = @"me";
static NSString *const FBSDKVideoUploaderEdge = @"videos";

@interface FBSDKVideoUploader ()

@property (nullable, nonatomic) NSNumber *uploadSessionID;
@property (nullable, nonatomic) NSString *graphPath;
@property (nonatomic) NSString *videoName;
@property (nonatomic) NSUInteger videoSize;
@property (nullable, nonatomic) NSNumber *videoID;
@property (nullable, nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

@end

@implementation FBSDKVideoUploader

#pragma mark Public Method
- (instancetype)initWithVideoName:(NSString *)videoName
                        videoSize:(NSUInteger)videoSize
                       parameters:(NSDictionary<NSString *, id> *)parameters
                         delegate:(id<_FBSDKVideoUploaderDelegate>)delegate
{
  return [self initWithVideoName:videoName
                       videoSize:videoSize
                      parameters:parameters
                        delegate:delegate
             graphRequestFactory:[FBSDKGraphRequestFactory new]];
}

- (instancetype)initWithVideoName:(NSString *)videoName
                        videoSize:(NSUInteger)videoSize
                       parameters:(NSDictionary<NSString *, id> *)parameters
                         delegate:(id<_FBSDKVideoUploaderDelegate>)delegate
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
{
  self = [super init];
  if (self) {
    _parameters = [parameters copy];
    _delegate = delegate;
    _graphNode = FBSDKVideoUploaderDefaultGraphNode;
    _videoName = videoName;
    _videoSize = videoSize;
    _graphRequestFactory = graphRequestFactory;
  }
  return self;
}

- (void)start
{
  self.graphPath = [self _graphPathWithSuffix:FBSDKVideoUploaderEdge, nil];
  [self _postStartRequest];
}

#pragma mark Helper Method

- (void)_postStartRequest
{
  FBSDKGraphRequestCompletion startRequestCompletionHandler = ^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];

    if (error) {
      [self.delegate videoUploader:self didFailWithError:error];
      return;
    } else {
      result = [self dictionaryValue:result];
      NSNumber *uploadSessionID = [self.numberFormatter numberFromString:result[FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID]];
      NSNumber *videoID = [self.numberFormatter numberFromString:result[FBSDK_GAMING_VIDEO_ID]];
      NSDictionary<NSString *, id> *offsetDictionary = [self _extractOffsetsFromResultDictionary:result];
      if (uploadSessionID == nil || videoID == nil) {
        NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                        code:0
                                                    userInfo:nil
                                                     message:@"Failed to get valid upload_session_id or video_id."
                                             underlyingError:nil];
        [self.delegate videoUploader:self didFailWithError:uploadError];
        return;
      } else if (offsetDictionary == nil) {
        return;
      }
      self->_uploadSessionID = uploadSessionID;
      self->_videoID = videoID;
      [self _startTransferRequestWithOffsetDictionary:offsetDictionary];
    }
  };
  if (self.videoSize == 0) {
    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
    NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                    code:0
                                                userInfo:nil
                                                 message:[NSString stringWithFormat:@"Invalid video size: %lu", (unsigned long)self.videoSize]
                                         underlyingError:nil];
    [self.delegate videoUploader:self didFailWithError:uploadError];
    return;
  }
  [[self.graphRequestFactory createGraphRequestWithGraphPath:self.graphPath parameters:@{
      FBSDK_GAMING_VIDEO_UPLOAD_PHASE : FBSDK_GAMING_VIDEO_UPLOAD_PHASE_START,
      FBSDK_GAMING_VIDEO_SIZE : [NSString stringWithFormat:@"%tu", self.videoSize],
    }
                                                  HTTPMethod:@"POST"] startWithCompletion:startRequestCompletionHandler];
}

- (void)_startTransferRequestWithOffsetDictionary:(NSDictionary<NSString *, id> *)offsetDictionary
{
  NSUInteger startOffset = [offsetDictionary[FBSDK_GAMING_VIDEO_START_OFFSET] unsignedIntegerValue];
  NSUInteger endOffset = [offsetDictionary[FBSDK_GAMING_VIDEO_END_OFFSET] unsignedIntegerValue];
  if (startOffset == endOffset) {
    [self _postFinishRequest];
    return;
  } else {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
      size_t chunkSize = (unsigned long)(endOffset - startOffset);
      NSData *data = [self.delegate videoChunkDataForVideoUploader:self startOffset:startOffset endOffset:endOffset];
      if (data == nil || data.length != chunkSize) {
        [self failVideoUploadForChunkSizeOffset:startOffset endOffset:endOffset];
      } else {
        [self _startTransferRequestWithNewOffset:offsetDictionary data:data];
      }
    });
  }
}

- (void)_postFinishRequest
{
  NSMutableDictionary<NSString *, id> *parameters = [NSMutableDictionary new];
  parameters[FBSDK_GAMING_VIDEO_UPLOAD_PHASE] = FBSDK_GAMING_VIDEO_UPLOAD_PHASE_FINISH;
  if (_uploadSessionID != nil) {
    parameters[FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID] = _uploadSessionID;
  }
  [parameters addEntriesFromDictionary:self.parameters];
  [[self.graphRequestFactory createGraphRequestWithGraphPath:_graphPath
                                                  parameters:parameters
                                                  HTTPMethod:@"POST"] startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
                                                    if (error) {
                                                      [self.delegate videoUploader:self didFailWithError:error];
                                                    } else {
                                                      result = [self dictionaryValue:result];
                                                      if (result[FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS] == nil) {
                                                        id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
                                                        NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                                                                        code:0
                                                                                                    userInfo:nil
                                                                                                     message:@"Failed to finish uploading."
                                                                                             underlyingError:nil];
                                                        [self.delegate videoUploader:self didFailWithError:uploadError];
                                                        return;
                                                      }
                                                      NSMutableDictionary<NSString *, id> *shareResult = [NSMutableDictionary new];
                                                      if (result[FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS]) {
                                                        shareResult[FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS] = result[FBSDK_GAMING_VIDEO_UPLOAD_SUCCESS];
                                                      }

                                                      shareResult[FBSDK_GAMING_RESULT_COMPLETION_GESTURE_KEY] = FBSDK_GAMING_RESULT_COMPLETION_GESTURE_VALUE_POST;

                                                      if (self->_videoID != nil) {
                                                        shareResult[FBSDK_GAMING_VIDEO_ID] = self->_videoID;
                                                      }

                                                      [self.delegate videoUploader:self didCompleteWithResults:shareResult];
                                                    }
                                                  }];
}

- (nullable NSDictionary<NSString *, id> *)_extractOffsetsFromResultDictionary:(id)result
{
  result = [self dictionaryValue:result];
  if (![result[FBSDK_GAMING_VIDEO_START_OFFSET] isKindOfClass:NSString.class]) {
    return nil;
  }
  if (![result[FBSDK_GAMING_VIDEO_END_OFFSET] isKindOfClass:NSString.class]) {
    return nil;
  }
  NSNumber *startNum = [self.numberFormatter numberFromString:result[FBSDK_GAMING_VIDEO_START_OFFSET]];
  NSNumber *endNum = [self.numberFormatter numberFromString:result[FBSDK_GAMING_VIDEO_END_OFFSET]];
  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
  if (startNum == nil || endNum == nil) {
    NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                    code:0
                                                userInfo:nil
                                                 message:@"Fail to get valid start_offset or end_offset."
                                         underlyingError:nil];
    [self.delegate videoUploader:self didFailWithError:uploadError];
    return nil;
  }
  if ([startNum compare:endNum] == NSOrderedDescending) {
    NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                    code:0
                                                userInfo:nil
                                                 message:@"Invalid offset: start_offset is greater than end_offset."
                                         underlyingError:nil];
    [self.delegate videoUploader:self didFailWithError:uploadError];
    return nil;
  }

  NSMutableDictionary<NSString *, id> *shareResults = [NSMutableDictionary new];

  if (startNum != nil) {
    shareResults[FBSDK_GAMING_VIDEO_START_OFFSET] = startNum;
  }

  if (endNum != nil) {
    shareResults[FBSDK_GAMING_VIDEO_END_OFFSET] = endNum;
  }

  return shareResults;
}

- (void)_startTransferRequestWithNewOffset:(NSDictionary<NSString *, id> *)offsetDictionary data:(nonnull NSData *)data
{
  FBSDKGraphRequestDataAttachment *dataAttachment = [[FBSDKGraphRequestDataAttachment alloc] initWithData:data
                                                                                                 filename:_videoName
                                                                                              contentType:@""];
  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:self.graphPath
                                                                                 parameters:@{
                                     FBSDK_GAMING_VIDEO_UPLOAD_PHASE : FBSDK_GAMING_VIDEO_UPLOAD_PHASE_TRANSFER,
                                     FBSDK_GAMING_VIDEO_START_OFFSET : offsetDictionary[FBSDK_GAMING_VIDEO_START_OFFSET],
                                     FBSDK_GAMING_VIDEO_UPLOAD_SESSION_ID : self.uploadSessionID,
                                     FBSDK_GAMING_VIDEO_FILE_CHUNK : dataAttachment,
                                   }
                                                                                 HTTPMethod:@"POST"];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *innerError) {
    if (innerError) {
      [self.delegate videoUploader:self didFailWithError:innerError];
      return;
    }
    NSDictionary<NSString *, id> *innerOffsetDictionary = [self _extractOffsetsFromResultDictionary:result];
    if (innerOffsetDictionary == nil) {
      return;
    }
    [self _startTransferRequestWithOffsetDictionary:innerOffsetDictionary];
  }];
}

- (void)failVideoUploadForChunkSizeOffset:(NSUInteger)startOffset endOffset:(NSUInteger)endOffset
{
  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
  NSString *message = [NSString stringWithFormat:@"Fail to get video chunk with start offset: %lu, end offset : %lu.",
                       (unsigned long)startOffset,
                       (unsigned long)endOffset];
  NSError *uploadError = [errorFactory errorWithDomain:FBSDKGamingVideoUploadErrorDomain
                                                  code:0
                                              userInfo:nil
                                               message:message
                                       underlyingError:nil];
  [self.delegate videoUploader:self didFailWithError:uploadError];
  return;
}

- (NSNumberFormatter *)numberFormatter
{
  if (!_numberFormatter) {
    _numberFormatter = [NSNumberFormatter new];
    _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  }
  return _numberFormatter;
}

- (NSString *)_graphPathWithSuffix:(NSString *)suffix, ... NS_REQUIRES_NIL_TERMINATION
{
  NSMutableString *graphPath = [[NSMutableString alloc] initWithString:self.graphNode];
  va_list args;
  va_start(args, suffix);
  for (NSString *arg = suffix; arg != nil; arg = va_arg(args, NSString *)) {
    [graphPath appendFormat:@"/%@", arg];
  }
  va_end(args);
  return graphPath;
}

- (NSDictionary<NSString *, id> *)dictionaryValue:(id)object
{
  return [object isKindOfClass:[NSDictionary<NSString *, id> class]] ? object : nil;
}

@end
