/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingImageUploaderConfiguration.h"

@implementation FBSDKGamingImageUploaderConfiguration

- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithImage:(UIImage *_Nonnull)image
                      caption:(NSString *_Nullable)caption
      shouldLaunchMediaDialog:(BOOL)shouldLaunchMediaDialog
{
  if ((self = [super init])) {
    _image = image;
    _caption = caption;
    _shouldLaunchMediaDialog = shouldLaunchMediaDialog;
  }
  return self;
}

@end
