/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSharePhoto.h"

#import <Photos/Photos.h>

#import "FBSDKHasher.h"
#import "FBSDKShareConstants.h"

NSString *const kFBSDKSharePhotoAssetKey = @"photoAsset";
NSString *const kFBSDKSharePhotoImageKey = @"image";
NSString *const kFBSDKSharePhotoImageURLKey = @"imageURL";
NSString *const kFBSDKSharePhotoUserGeneratedKey = @"userGenerated";
NSString *const kFBSDKSharePhotoCaptionKey = @"caption";

@implementation FBSDKSharePhoto

#pragma mark - Class Methods

+ (instancetype)photoWithImage:(UIImage *)image userGenerated:(BOOL)userGenerated
{
  FBSDKSharePhoto *photo = [self new];
  photo.image = image;
  photo.userGenerated = userGenerated;
  return photo;
}

+ (instancetype)photoWithImageURL:(NSURL *)imageURL userGenerated:(BOOL)userGenerated
{
  FBSDKSharePhoto *photo = [self new];
  photo.imageURL = imageURL;
  photo.userGenerated = userGenerated;
  return photo;
}

+ (instancetype)photoWithPhotoAsset:(PHAsset *)photoAsset userGenerated:(BOOL)userGenerated
{
  FBSDKSharePhoto *photo = [self new];
  photo.photoAsset = photoAsset;
  photo.userGenerated = userGenerated;
  return photo;
}

#pragma mark - Properties

- (void)setImage:(UIImage *)image
{
  _image = image;
  _imageURL = nil;
  _photoAsset = nil;
}

- (void)setImageURL:(NSURL *)imageURL
{
  _image = nil;
  _imageURL = [imageURL copy];
  _photoAsset = nil;
}

- (void)setPhotoAsset:(PHAsset *)photoAsset
{
  _image = nil;
  _imageURL = nil;
  _photoAsset = [photoAsset copy];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _image.hash,
    _imageURL.hash,
    _photoAsset.hash,
    _caption.hash,
    (_userGenerated ? 1u : 0u)
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKSharePhoto.class]) {
    return NO;
  }
  return [self isEqualToSharePhoto:(FBSDKSharePhoto *)object];
}

- (BOOL)isEqualToSharePhoto:(FBSDKSharePhoto *)photo
{
  return (photo
    && (_userGenerated == photo.userGenerated)
    && [FBSDKInternalUtility.sharedUtility object:_image isEqualToObject:photo.image]
    && [FBSDKInternalUtility.sharedUtility object:_imageURL isEqualToObject:photo.imageURL]
    && [FBSDKInternalUtility.sharedUtility object:_photoAsset isEqualToObject:photo.photoAsset]
    && [FBSDKInternalUtility.sharedUtility object:_caption isEqualToObject:photo.caption]);
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (bridgeOptions & FBSDKShareBridgeOptionsPhotoImageURL) { // a web-based URL is required
    if (_imageURL) {
      if (_imageURL.isFileURL) {
        if (errorRef != NULL) {
          *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"imageURL"
                                                           value:_imageURL
                                                         message:@"Cannot refer to a local file resource."];
        }
        return NO;
      } else {
        return YES; // will bridge the image URL
      }
    } else {
      if (errorRef != NULL) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"photo"
                                                         value:self
                                                       message:@"imageURL is required."];
      }
      return NO;
    }
  } else if (_photoAsset) {
    if (PHAssetMediaTypeImage == _photoAsset.mediaType) {
      if (bridgeOptions & FBSDKShareBridgeOptionsPhotoAsset) {
        return YES; // will bridge the PHAsset.localIdentifier
      } else {
        return YES; // will load the asset and bridge the image
      }
    } else {
      if (errorRef != NULL) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"photoAsset"
                                                         value:_photoAsset
                                                       message:@"Must refer to a photo or other static image."];
      }
      return NO;
    }
  } else if (_imageURL) {
    if (_imageURL.isFileURL) {
      return YES; // will load the contents of the file and bridge the image
    } else {
      if (errorRef != NULL) {
        *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"imageURL"
                                                         value:_imageURL
                                                       message:@"Must refer to a local file resource."];
      }
      return NO;
    }
  } else if (_image) {
    return YES; // will bridge the image
  } else {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"photo"
                                                       value:self
                                                     message:@"Must have an asset, image, or imageURL value."];
    }
    return NO;
  }
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _image = [decoder decodeObjectOfClass:UIImage.class forKey:kFBSDKSharePhotoImageKey];
    _imageURL = [decoder decodeObjectOfClass:NSURL.class forKey:kFBSDKSharePhotoImageURLKey];
    NSString *localIdentifier = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKSharePhotoAssetKey];
    if (localIdentifier && (PHAuthorizationStatusAuthorized == [PHPhotoLibrary authorizationStatus])) {
      _photoAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil].firstObject;
    }
    _userGenerated = [decoder decodeBoolForKey:kFBSDKSharePhotoUserGeneratedKey];
    _caption = [decoder decodeObjectOfClass:NSString.class forKey:kFBSDKSharePhotoCaptionKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_image forKey:kFBSDKSharePhotoImageKey];
  [encoder encodeObject:_imageURL forKey:kFBSDKSharePhotoImageURLKey];
  [encoder encodeObject:_photoAsset.localIdentifier forKey:kFBSDKSharePhotoAssetKey];
  [encoder encodeBool:_userGenerated forKey:kFBSDKSharePhotoUserGeneratedKey];
  [encoder encodeObject:_caption forKey:kFBSDKSharePhotoCaptionKey];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKSharePhoto *copy = [FBSDKSharePhoto new];
  copy->_image = [_image copy];
  copy->_imageURL = [_imageURL copy];
  copy->_photoAsset = [_photoAsset copy];
  copy->_userGenerated = _userGenerated;
  copy->_caption = [_caption copy];
  return copy;
}

@end
