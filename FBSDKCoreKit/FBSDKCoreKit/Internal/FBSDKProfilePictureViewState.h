/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKProfilePictureMode.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKProfilePictureViewState : NSObject

- (instancetype)initWithProfileID:(NSString *)profileID
                             size:(CGSize)size
                            scale:(CGFloat)scale
                      pictureMode:(FBSDKProfilePictureMode)pictureMode
                   imageShouldFit:(BOOL)imageShouldFit;

@property (nonatomic, readonly, assign) BOOL imageShouldFit;
@property (nonatomic, readonly, assign) FBSDKProfilePictureMode pictureMode;
@property (nonatomic, readonly, copy) NSString *profileID;
@property (nonatomic, readonly, assign) CGFloat scale;
@property (nonatomic, readonly, assign) CGSize size;

- (BOOL)isEqualToState:(FBSDKProfilePictureViewState *)other;
- (BOOL)isValidForState:(FBSDKProfilePictureViewState *)other;

@end

NS_ASSUME_NONNULL_END

#endif
