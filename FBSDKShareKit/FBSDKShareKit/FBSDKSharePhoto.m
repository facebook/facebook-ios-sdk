/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSharePhoto.h"

#import <Photos/Photos.h>

#import <FBSDKShareKit/FBSDKShareErrorDomain.h>

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

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];

  if (bridgeOptions & FBSDKShareBridgeOptionsPhotoImageURL) { // a web-based URL is required
    if (_imageURL) {
      if (_imageURL.isFileURL) {
        if (errorRef != NULL) {
          *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                              name:@"imageURL"
                                                             value:_imageURL
                                                           message:@"Cannot refer to a local file resource."
                                                   underlyingError:nil];
        }
        return NO;
      } else {
        return YES; // will bridge the image URL
      }
    } else {
      if (errorRef != NULL) {
        *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"photo"
                                                           value:self
                                                         message:@"imageURL is required."
                                                 underlyingError:nil];
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
        *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"photoAsset"
                                                           value:_photoAsset
                                                         message:@"Must refer to a photo or other static image."
                                                 underlyingError:nil];
      }
      return NO;
    }
  } else if (_imageURL) {
    if (_imageURL.isFileURL) {
      return YES; // will load the contents of the file and bridge the image
    } else {
      if (errorRef != NULL) {
        *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"imageURL"
                                                           value:_imageURL
                                                         message:@"Must refer to a local file resource."
                                                 underlyingError:nil];
      }
      return NO;
    }
  } else if (_image) {
    return YES; // will bridge the image
  } else {
    if (errorRef != NULL) {
      *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                          name:@"photo"
                                                         value:self
                                                       message:@"Must have an asset, image, or imageURL value."
                                               underlyingError:nil];
    }
    return NO;
  }
}

@end
