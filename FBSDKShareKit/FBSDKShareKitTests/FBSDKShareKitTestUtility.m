/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareKitTestUtility.h"

@implementation FBSDKShareKitTestUtility

+ (UIImage *)testImage
{
  static UIImage *image = nil;
  if (image == nil) {
    NSData *imageData = [NSData dataWithContentsOfURL:[self.class testImageURL]];
    image = [UIImage imageWithData:imageData];
  }
  return image;
}

+ (NSURL *)testImageURL
{
  NSBundle *bundle = [NSBundle bundleForClass:self.class];
  NSURL *imageURL = [bundle URLForResource:@"test-image" withExtension:@"jpeg"];
  return imageURL;
}

+ (NSURL *)testPNGImageURL
{
  NSBundle *bundle = [NSBundle bundleForClass:self.class];
  NSURL *imageURL = [bundle URLForResource:@"bicycle" withExtension:@"png"];
  return imageURL;
}

@end
