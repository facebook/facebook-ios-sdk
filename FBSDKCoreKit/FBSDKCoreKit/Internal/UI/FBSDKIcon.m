/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKIcon+Internal.h"

@implementation FBSDKIcon

#pragma mark - Public API

- (UIImage *)imageWithSize:(CGSize)size
{
  return [self imageWithSize:size scale:UIScreen.mainScreen.scale color:UIColor.whiteColor];
}

- (UIImage *)imageWithSize:(CGSize)size scale:(CGFloat)scale
{
  return [self imageWithSize:size scale:scale color:UIColor.whiteColor];
}

- (UIImage *)imageWithSize:(CGSize)size color:(UIColor *)color
{
  return [self imageWithSize:size scale:UIScreen.mainScreen.scale color:color];
}

- (nullable UIImage *)imageWithSize:(CGSize)size scale:(CGFloat)scale color:(UIColor *)color
{
  if ((size.width == 0) || (size.height == 0)) {
    return nil;
  }
  UIGraphicsBeginImageContextWithOptions(size, NO, scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGPathRef path = [self pathWithSize:size];
  CGContextAddPath(context, path);
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextFillPath(context);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (nullable CGPathRef)pathWithSize:(CGSize)size
{
  return NULL;
}

@end
