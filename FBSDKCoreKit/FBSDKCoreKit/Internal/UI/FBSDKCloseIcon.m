/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKCloseIcon.h"

@implementation FBSDKCloseIcon

#pragma mark - Public API

- (UIImage *)imageWithSize:(CGSize)size
{
  return [self imageWithSize:size
                primaryColor:UIColor.whiteColor
              secondaryColor:UIColor.blackColor
                       scale:UIScreen.mainScreen.scale];
}

- (UIImage *)imageWithSize:(CGSize)size
              primaryColor:(UIColor *)primaryColor
            secondaryColor:(UIColor *)secondaryColor
                     scale:(CGFloat)scale
{
  UIGraphicsBeginImageContextWithOptions(size, NO, scale);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGFloat iconSize = MIN(size.width, size.height);

  CGRect rect = CGRectMake((size.width - iconSize) / 2, (size.height - iconSize) / 2, iconSize, iconSize);
  CGFloat step = iconSize / 12;

  // shadow
  rect = CGRectIntegral(CGRectInset(rect, step, step));
  NSArray *colors = @[
    (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.7].CGColor,
    (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
    (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.1].CGColor,
    (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
  ];
  CGFloat locations[4] = {
    0.70,
    0.80,
    0.90,
    1.0,
  };
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
  CGColorSpaceRelease(colorSpace);
  CGPoint center = CGPointMake(CGRectGetMidX(rect) - step / 6, CGRectGetMidY(rect) + step / 4);
  CGContextDrawRadialGradient(context, gradient, center, 0.0, center, (CGRectGetWidth(rect) - step / 2) / 2, 0);
  CGGradientRelease(gradient);

  // outer circle
  rect = CGRectIntegral(CGRectInset(rect, step, step));
  [primaryColor setFill];
  CGContextFillEllipseInRect(context, rect);

  // inner circle
  rect = CGRectIntegral(CGRectInset(rect, step, step));
  [secondaryColor setFill];
  CGContextFillEllipseInRect(context, rect);

  // cross
  rect = CGRectIntegral(CGRectInset(rect, step, step));
  CGFloat lineWidth = step * 5 / 4;
  rect.origin.y = CGRectGetMidY(rect) - lineWidth / 2;
  rect.size.height = lineWidth;
  [primaryColor setFill];
  CGContextTranslateCTM(context, size.width / 2, size.height / 2);
  CGContextRotateCTM(context, M_PI_4);
  CGContextTranslateCTM(context, -size.width / 2, -size.height / 2);
  CGContextFillRect(context, rect);
  CGContextTranslateCTM(context, size.width / 2, size.height / 2);
  CGContextRotateCTM(context, M_PI_2);
  CGContextTranslateCTM(context, -size.width / 2, -size.height / 2);
  CGContextFillRect(context, rect);

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@end

#endif
