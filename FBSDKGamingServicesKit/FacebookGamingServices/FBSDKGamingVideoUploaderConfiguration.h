/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GamingVideoUploaderConfiguration)
@interface FBSDKGamingVideoUploaderConfiguration : NSObject

@property (nonnull, nonatomic, readonly, strong) NSURL *videoURL;
@property (nullable, nonatomic, readonly, strong) NSString *caption;

- (instancetype _Nonnull)init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
A model for Gaming video upload content to be shared.

@param videoURL a url to the videos location on local disk.
@param caption and optional caption that will appear along side the video on Facebook.
*/
- (instancetype)initWithVideoURL:(NSURL *_Nonnull)videoURL
                         caption:(NSString *_Nullable)caption;

@end

NS_ASSUME_NONNULL_END
