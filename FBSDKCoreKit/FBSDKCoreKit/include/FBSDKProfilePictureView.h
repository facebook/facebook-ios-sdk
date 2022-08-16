/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKProfilePictureMode.h>

@class FBSDKProfile;

NS_ASSUME_NONNULL_BEGIN

/// A view to display a profile picture.
NS_SWIFT_NAME(FBProfilePictureView)
@interface FBSDKProfilePictureView : UIView

/**
 Create a new instance of `FBSDKProfilePictureView`.

 - Parameter frame: Frame rectangle for the view.
 - Parameter profile: Optional profile to display a picture for.
 */
- (instancetype)initWithFrame:(CGRect)frame
                      profile:(FBSDKProfile *_Nullable)profile;

/**
 Create a new instance of `FBSDKProfilePictureView`.

 - Parameter profile: Optional profile to display a picture for.
 */
- (instancetype)initWithProfile:(FBSDKProfile *_Nullable)profile;

/// The mode for the receiver to determine the aspect ratio of the source image.
@property (nonatomic, assign) FBSDKProfilePictureMode pictureMode;

/// The profile ID to show the picture for.
@property (nonatomic, copy) NSString *profileID;

/**
 Explicitly marks the receiver as needing to update the image.

 This method is called whenever any properties that affect the source image are modified, but this can also
 be used to trigger a manual update of the image if it needs to be re-downloaded.
 */
- (void)setNeedsImageUpdate;

@end

NS_ASSUME_NONNULL_END

#endif
