/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKVideoUploaderDelegate;
@protocol FBSDKGraphRequestFactory;

@interface FBSDKVideoUploader (Testing)

@property (nonatomic, copy) NSNumber *uploadSessionID;

- (void)start;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithVideoName:(NSString *)videoName
                        videoSize:(NSUInteger)videoSize
                       parameters:(NSDictionary<NSString *, id> *)parameters
                         delegate:(id<FBSDKVideoUploaderDelegate>)delegate
              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
NS_SWIFT_NAME(init(videoName:videoSize:parameters:delegate:graphRequestFactory:));
// UNCRUSTIFY_FORMAT_ON

- (void)_postFinishRequest;

- (void)_startTransferRequestWithOffsetDictionary:(NSDictionary<NSString *, id> *)offsetDictionary;

- (NSNumberFormatter *)numberFormatter;

- (NSDictionary<NSString *, id> *)_extractOffsetsFromResultDictionary:(id)result;

- (void)_startTransferRequestWithNewOffset:(NSDictionary<NSString *, id> *)offsetDictionary
                                      data:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
