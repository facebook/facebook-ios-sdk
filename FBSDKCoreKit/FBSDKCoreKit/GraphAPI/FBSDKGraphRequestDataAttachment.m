/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestDataAttachment.h"

@implementation FBSDKGraphRequestDataAttachment

- (instancetype)initWithData:(NSData *)data filename:(NSString *)filename contentType:(NSString *)contentType
{
  if ((self = [super init])) {
    _data = data;
    _filename = [filename copy];
    _contentType = [contentType copy];
  }
  return self;
}

@end
