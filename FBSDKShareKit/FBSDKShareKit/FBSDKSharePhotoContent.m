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

#import "FBSDKHasher.h"
#import "FBSDKHashtag.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKShareUtility.h"

#define FBSDK_SHARE_PHOTO_CONTENT_CONTENT_URL_KEY @"contentURL"
#define FBSDK_SHARE_PHOTO_CONTENT_HASHTAG_KEY @"hashtag"
#define FBSDK_SHARE_PHOTO_CONTENT_PEOPLE_IDS_KEY @"peopleIDs"
#define FBSDK_SHARE_PHOTO_CONTENT_PHOTOS_KEY @"photos"
#define FBSDK_SHARE_PHOTO_CONTENT_PLACE_ID_KEY @"placeID"
#define FBSDK_SHARE_PHOTO_CONTENT_REF_KEY @"ref"
#define FBSDK_SHARE_PHOTO_CONTENT_PAGE_ID_KEY @"pageID"
#define FBSDK_SHARE_PHOTO_CONTENT_UUID_KEY @"uuid"

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
  if (![FBSDKShareUtility validateArray:_photos minCount:1 maxCount:6 name:@"photos" error:errorRef]) {
    return NO;
  }
  for (FBSDKSharePhoto *photo in _photos) {
    if (![photo validateWithOptions:bridgeOptions error:errorRef]) {
      return NO;
    }
  }
  return YES;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _contentURL.hash,
    _hashtag.hash,
    _peopleIDs.hash,
    _photos.hash,
    _placeID.hash,
    _ref.hash,
    _pageID.hash,
    _shareUUID.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKSharePhotoContent.class]) {
    return NO;
  }
  return [self isEqualToSharePhotoContent:(FBSDKSharePhotoContent *)object];
}

- (BOOL)isEqualToSharePhotoContent:(FBSDKSharePhotoContent *)content
{
  return (content
    && [FBSDKInternalUtility.sharedUtility object:_contentURL isEqualToObject:content.contentURL]
    && [FBSDKInternalUtility.sharedUtility object:_hashtag isEqualToObject:content.hashtag]
    && [FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:content.peopleIDs]
    && [FBSDKInternalUtility.sharedUtility object:_photos isEqualToObject:content.photos]
    && [FBSDKInternalUtility.sharedUtility object:_placeID isEqualToObject:content.placeID]
    && [FBSDKInternalUtility.sharedUtility object:_ref isEqualToObject:content.ref]
    && [FBSDKInternalUtility.sharedUtility object:_shareUUID isEqualToObject:content.shareUUID]
    && [FBSDKInternalUtility.sharedUtility object:_pageID isEqualToObject:content.pageID]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _contentURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SHARE_PHOTO_CONTENT_CONTENT_URL_KEY];
    _hashtag = [decoder decodeObjectOfClass:FBSDKHashtag.class forKey:FBSDK_SHARE_PHOTO_CONTENT_HASHTAG_KEY];
    _peopleIDs = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_SHARE_PHOTO_CONTENT_PEOPLE_IDS_KEY];
    NSSet<Class> *classes = [NSSet setWithObjects:NSArray.class, FBSDKSharePhoto.class, nil];
    _photos = [decoder decodeObjectOfClasses:classes forKey:FBSDK_SHARE_PHOTO_CONTENT_PHOTOS_KEY];
    _placeID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_PHOTO_CONTENT_PLACE_ID_KEY];
    _ref = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_PHOTO_CONTENT_REF_KEY];
    _pageID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_PHOTO_CONTENT_PAGE_ID_KEY];
    _shareUUID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_PHOTO_CONTENT_UUID_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_contentURL forKey:FBSDK_SHARE_PHOTO_CONTENT_CONTENT_URL_KEY];
  [encoder encodeObject:_hashtag forKey:FBSDK_SHARE_PHOTO_CONTENT_HASHTAG_KEY];
  [encoder encodeObject:_peopleIDs forKey:FBSDK_SHARE_PHOTO_CONTENT_PEOPLE_IDS_KEY];
  [encoder encodeObject:_photos forKey:FBSDK_SHARE_PHOTO_CONTENT_PHOTOS_KEY];
  [encoder encodeObject:_placeID forKey:FBSDK_SHARE_PHOTO_CONTENT_PLACE_ID_KEY];
  [encoder encodeObject:_ref forKey:FBSDK_SHARE_PHOTO_CONTENT_REF_KEY];
  [encoder encodeObject:_pageID forKey:FBSDK_SHARE_PHOTO_CONTENT_PAGE_ID_KEY];
  [encoder encodeObject:_shareUUID forKey:FBSDK_SHARE_PHOTO_CONTENT_UUID_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKSharePhotoContent *copy = [FBSDKSharePhotoContent new];
  copy->_contentURL = [_contentURL copy];
  copy->_hashtag = [_hashtag copy];
  copy->_peopleIDs = [_peopleIDs copy];
  copy->_photos = [_photos copy];
  copy->_placeID = [_placeID copy];
  copy->_ref = [_ref copy];
  copy->_pageID = [_pageID copy];
  copy->_shareUUID = [_shareUUID copy];
  return copy;
}

@end
