/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKVideoUploading.h"

@protocol FBSDKVideoUploaderDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VideoUploaderCreating)
@protocol FBSDKVideoUploaderCreating

// UNCRUSTIFY_FORMAT_OFF
- (id<FBSDKVideoUploading>)createWithVideoName:(NSString *)videoName
                                     videoSize:(NSUInteger)videoSize
                                    parameters:(NSDictionary<NSString *, id> *)parameters
                                      delegate:(id<FBSDKVideoUploaderDelegate>)delegate
NS_SWIFT_NAME(create(videoName:videoSize:parameters:delegate:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
