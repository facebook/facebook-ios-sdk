// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKShareVideo.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKSharePhoto.h"

#define FBSDK_SHARE_VIDEO_URL_KEY @"videoURL"
#define FBSDK_SHARE_VIDEO_PREVIEW_PHOTO_KEY @"previewPhoto"

@implementation FBSDKShareVideo

#pragma mark - Class Methods

+ (instancetype)videoWithVideoURL:(NSURL *)videoURL
{
  FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
  video.videoURL = videoURL;
  return video;
}

+ (instancetype)videoWithVideoURL:(NSURL *)videoURL previewPhoto:(FBSDKSharePhoto *)previewPhoto
{
  FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
  video.videoURL = videoURL;
  video.previewPhoto = previewPhoto;
  return video;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    [_videoURL hash],
    [_previewPhoto hash],
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKShareVideo class]]) {
    return NO;
  }
  return [self isEqualToShareVideo:(FBSDKShareVideo *)object];
}

- (BOOL)isEqualToShareVideo:(FBSDKShareVideo *)video
{
  return (video &&
          [FBSDKInternalUtility object:_videoURL isEqualToObject:video.videoURL] &&
          [FBSDKInternalUtility object:_previewPhoto isEqualToObject:video.previewPhoto]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _videoURL = [decoder decodeObjectOfClass:[NSURL class] forKey:FBSDK_SHARE_VIDEO_URL_KEY];
    _previewPhoto = [decoder decodeObjectOfClass:[FBSDKSharePhoto class] forKey:FBSDK_SHARE_VIDEO_PREVIEW_PHOTO_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_videoURL forKey:FBSDK_SHARE_VIDEO_URL_KEY];
  [encoder encodeObject:_previewPhoto forKey:FBSDK_SHARE_VIDEO_PREVIEW_PHOTO_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKShareVideo *copy = [[FBSDKShareVideo alloc] init];
  copy->_videoURL = [_videoURL copy];
  copy->_previewPhoto = [_previewPhoto copy];
  return copy;
}

@end
