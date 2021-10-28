/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ShareKitTestUtility)
@interface FBSDKShareKitTestUtility : NSObject

/*!
 * @abstract Returns a UIImage for sharing.
 */
+ (UIImage *)testImage;

/*!
 * @abstract Returns an NSURL to JPEG image data in the bundle.
 */
+ (NSURL *)testImageURL;

/*!
 * @abstract Returns an NSURL to PNG image data in the bundle.
 */
+ (NSURL *)testPNGImageURL;

@end

NS_ASSUME_NONNULL_END
