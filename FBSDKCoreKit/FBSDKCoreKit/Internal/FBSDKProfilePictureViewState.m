/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <FBSDKCoreKit/FBSDKInternalUtility.h>

#import "FBSDKProfilePictureViewState.h"
#import "FBSDKMath.h"

@implementation FBSDKProfilePictureViewState

- (instancetype)initWithProfileID:(NSString *)profileID
                             size:(CGSize)size
                            scale:(CGFloat)scale
                      pictureMode:(FBSDKProfilePictureMode)pictureMode
                   imageShouldFit:(BOOL)imageShouldFit
{
  if ((self = [super init])) {
    _profileID = [profileID copy];
    _size = size;
    _scale = scale;
    _pictureMode = pictureMode;
    _imageShouldFit = imageShouldFit;
  }
  return self;
}

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    (NSUInteger)_imageShouldFit,
    (NSUInteger)_size.width,
    (NSUInteger)_size.height,
    (NSUInteger)_scale,
    (NSUInteger)_pictureMode,
    _profileID.hash,
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:FBSDKProfilePictureViewState.class]) {
    return NO;
  }
  FBSDKProfilePictureViewState *other = (FBSDKProfilePictureViewState *)object;
  return [self isEqualToState:other];
}

- (BOOL)isEqualToState:(FBSDKProfilePictureViewState *)other
{
  return ([self isValidForState:other]
    && CGSizeEqualToSize(_size, other->_size)
    && (_scale == other->_scale));
}

- (BOOL)isValidForState:(FBSDKProfilePictureViewState *)other
{
  return (other != nil
    && (_imageShouldFit == other->_imageShouldFit)
    && (_pictureMode == other->_pictureMode)
    && [FBSDKInternalUtility.sharedUtility object:_profileID isEqualToObject:other->_profileID]);
}

@end

#endif
