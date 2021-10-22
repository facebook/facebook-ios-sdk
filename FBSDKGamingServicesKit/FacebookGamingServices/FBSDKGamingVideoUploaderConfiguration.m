/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGamingVideoUploaderConfiguration.h"

@implementation FBSDKGamingVideoUploaderConfiguration

- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithVideoURL:(NSURL *_Nonnull)videoURL
                         caption:(NSString *_Nullable)caption;
{
  if ((self = [super init])) {
    _videoURL = videoURL;
    _caption = caption;
  }
  return self;
}

@end
