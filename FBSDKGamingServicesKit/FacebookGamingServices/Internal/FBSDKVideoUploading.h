/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

@protocol FBSDKVideoUploaderDelegate;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(VideoUploading)
@protocol FBSDKVideoUploading

@property (nonatomic, weak) id<FBSDKVideoUploaderDelegate> delegate;

- (void)start;

@end

NS_ASSUME_NONNULL_END
