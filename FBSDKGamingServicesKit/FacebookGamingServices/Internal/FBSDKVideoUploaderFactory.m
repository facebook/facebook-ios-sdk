/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKVideoUploaderFactory.h"

#import <FacebookGamingServices/FacebookGamingServices-Swift.h>

#import "FBSDKVideoUploader.h"

@implementation FBSDKVideoUploaderFactory

- (id<FBSDKVideoUploading>)createWithVideoName:(NSString *)videoName
                                     videoSize:(NSUInteger)videoSize
                                    parameters:(NSDictionary<NSString *, id> *)parameters
                                      delegate:(id<FBSDKVideoUploaderDelegate>)delegate
{
  return [[FBSDKVideoUploader alloc]
          initWithVideoName:videoName
          videoSize:videoSize
          parameters:parameters ?: @{}
          delegate:delegate];
}

@end
