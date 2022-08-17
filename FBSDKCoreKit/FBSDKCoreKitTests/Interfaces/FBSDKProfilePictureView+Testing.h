/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKProfilePictureView.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKProfilePictureViewState;

@interface FBSDKProfilePictureView (Testing)

@property (nonatomic) BOOL hasProfileImage;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic, nullable) FBSDKProfilePictureViewState *lastState;
@property (nonatomic) BOOL needsImageUpdate;
@property (nonatomic) BOOL placeholderImageIsValid;

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification;
- (void)_profileDidChangeNotification:(NSNotification *)notification;
- (void)_updateImageWithProfile;
- (void)_updateImageWithAccessToken;
- (void)_updateImage;
- (void)_fetchAndSetImageWithURL:(NSURL *)imageURL state:(FBSDKProfilePictureViewState *)state;
- (nullable FBSDKProfilePictureViewState *)lastState;
- (void)_setPlaceholderImage;
- (void)_updateImageWithData:(NSData *)data state:(FBSDKProfilePictureViewState *)state;
@end

NS_ASSUME_NONNULL_END
