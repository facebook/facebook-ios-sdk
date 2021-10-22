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

NS_SWIFT_NAME(GamingImageUploaderConfiguration)
@interface FBSDKGamingImageUploaderConfiguration : NSObject

@property (nonatomic, strong, readonly, nonnull) UIImage *image;
@property (nonatomic, strong, readonly, nullable) NSString *caption;
@property (nonatomic, assign, readonly) BOOL shouldLaunchMediaDialog;

- (instancetype _Nonnull )init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
 A model for Gaming image upload content to be shared.

 @param image the image that will be shared.
 @param caption and optional caption that will appear along side the image on Facebook.
 @param shouldLaunchMediaDialog whether or not to open the media dialog on
  Facebook when the upload completes.
 */
- (instancetype)initWithImage:(UIImage * _Nonnull)image
                      caption:(NSString * _Nullable)caption
      shouldLaunchMediaDialog:(BOOL)shouldLaunchMediaDialog;

@end

NS_ASSUME_NONNULL_END
