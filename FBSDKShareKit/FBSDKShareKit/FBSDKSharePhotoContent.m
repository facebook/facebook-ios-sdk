/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKSharePhotoContent.h"

#import <Photos/Photos.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <FBSDKShareKit/_FBSDKShareUtility.h>

#import "FBSDKHashtag.h"
#import "FBSDKSharePhoto.h"

@implementation FBSDKSharePhotoContent

#pragma mark - Properties

@synthesize contentURL = _contentURL;
@synthesize hashtag = _hashtag;
@synthesize peopleIDs = _peopleIDs;
@synthesize placeID = _placeID;
@synthesize ref = _ref;
@synthesize pageID = _pageID;
@synthesize shareUUID = _shareUUID;

#pragma mark - Initializer

- (instancetype)init
{
  self = [super init];
  if (self) {
    _shareUUID = [NSUUID UUID].UUIDString;
  }
  return self;
}

#pragma mark - FBSDKSharingContent

- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
{
  NSMutableDictionary<NSString *, id> *updatedParameters = [NSMutableDictionary dictionaryWithDictionary:existingParameters];

  NSMutableArray<UIImage *> *images = [NSMutableArray new];
  for (FBSDKSharePhoto *photo in _photos) {
    if (photo.photoAsset) {
      // load the asset and bridge the image
      PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
      imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
      imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
      imageRequestOptions.synchronous = YES;
      [[PHImageManager defaultManager]
       requestImageForAsset:photo.photoAsset
       targetSize:PHImageManagerMaximumSize
       contentMode:PHImageContentModeDefault
       options:imageRequestOptions
       resultHandler:^(UIImage *image, NSDictionary<NSString *, id> *info) {
         if (image) {
           [FBSDKTypeUtility array:images addObject:image];
         }
       }];
    } else if (photo.imageURL) {
      if (photo.imageURL.isFileURL) {
        // load the contents of the file and bridge the image
        UIImage *image = [UIImage imageWithContentsOfFile:photo.imageURL.path];
        if (image) {
          [FBSDKTypeUtility array:images addObject:image];
        }
      }
    } else if (photo.image) {
      // bridge the image
      [FBSDKTypeUtility array:images addObject:photo.image];
    }
  }
  if (images.count > 0) {
    [FBSDKTypeUtility dictionary:updatedParameters
                       setObject:images
                          forKey:@"photos"];
  }

  return updatedParameters;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (![_FBSDKShareUtility validateArray:_photos minCount:1 maxCount:6 name:@"photos" error:errorRef]) {
    return NO;
  }
  for (FBSDKSharePhoto *photo in _photos) {
    if (![photo validateWithOptions:bridgeOptions error:errorRef]) {
      return NO;
    }
  }
  return YES;
}

@end
