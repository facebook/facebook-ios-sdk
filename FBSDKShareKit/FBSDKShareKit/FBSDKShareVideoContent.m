/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareVideoContent.h"

#import <Photos/Photos.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKHasher.h"
#import "FBSDKHashtag.h"
#import "FBSDKShareUtility.h"

#define FBSDK_SHARE_VIDEO_CONTENT_CONTENT_URL_KEY @"contentURL"
#define FBSDK_SHARE_VIDEO_CONTENT_HASHTAG_KEY @"hashtag"
#define FBSDK_SHARE_VIDEO_CONTENT_PEOPLE_IDS_KEY @"peopleIDs"
#define FBSDK_SHARE_VIDEO_CONTENT_PLACE_ID_KEY @"placeID"
#define FBSDK_SHARE_VIDEO_CONTENT_PREVIEW_PHOTO_KEY @"previewPhoto"
#define FBSDK_SHARE_VIDEO_CONTENT_REF_KEY @"ref"
#define FBSDK_SHARE_VIDEO_CONTENT_PAGE_ID_KEY @"pageID"
#define FBSDK_SHARE_VIDEO_CONTENT_VIDEO_KEY @"video"
#define FBSDK_SHARE_VIDEO_CONTENT_UUID_KEY @"uuid"

@implementation FBSDKShareVideoContent

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

#pragma mark - Setters

- (void)setPeopleIDs:(NSArray *)peopleIDs
{
  [FBSDKShareUtility assertCollection:peopleIDs ofClass:NSString.class name:@"peopleIDs"];
  if (![FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:peopleIDs]) {
    _peopleIDs = [peopleIDs copy];
  }
}

#pragma mark - FBSDKSharingContent

- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
{
  NSMutableDictionary<NSString *, id> *updatedParameters = [NSMutableDictionary dictionaryWithDictionary:existingParameters];

  NSMutableDictionary<NSString *, id> *videoParameters = [NSMutableDictionary new];
  if (_video.videoAsset) {
    if (bridgeOptions & FBSDKShareBridgeOptionsVideoAsset) {
      // bridge the PHAsset.localIdentifier
      [FBSDKTypeUtility dictionary:videoParameters
                         setObject:_video.videoAsset.localIdentifier
                            forKey:@"assetIdentifier"];
    } else {
      // bridge the legacy "assets-library" URL from AVAsset
      [FBSDKTypeUtility dictionary:videoParameters
                         setObject:_video.videoAsset.videoURL
                            forKey:@"assetURL"];
    }
  } else if (_video.data) {
    if (bridgeOptions & FBSDKShareBridgeOptionsVideoData) {
      // bridge the data
      [FBSDKTypeUtility dictionary:videoParameters
                         setObject:_video.data
                            forKey:@"data"];
    }
  } else if (_video.videoURL) {
    if ([_video.videoURL.scheme.lowercaseString isEqualToString:@"assets-library"]) {
      // bridge the legacy "assets-library" URL
      [FBSDKTypeUtility dictionary:videoParameters
                         setObject:_video.videoURL
                            forKey:@"assetURL"];
    } else if (_video.videoURL.isFileURL) {
      if (bridgeOptions & FBSDKShareBridgeOptionsVideoData) {
        // load the contents of the file and bridge the data
        NSData *data = [NSData dataWithContentsOfURL:_video.videoURL options:NSDataReadingMappedIfSafe error:NULL];
        [FBSDKTypeUtility dictionary:videoParameters
                           setObject:data
                              forKey:@"data"];
      }
    }
  }

  if (_video.previewPhoto) {
    [FBSDKTypeUtility dictionary:videoParameters
                       setObject:[FBSDKShareUtility convertPhoto:_video.previewPhoto]
                          forKey:@"previewPhoto"];
  }

  [FBSDKTypeUtility dictionary:updatedParameters
                     setObject:videoParameters
                        forKey:@"video"];

  return updatedParameters;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKShareUtility validateRequiredValue:_video name:@"video" error:errorRef]) {
    return NO;
  }
  return [_video validateWithOptions:bridgeOptions error:errorRef];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _contentURL.hash,
    _hashtag.hash,
    _peopleIDs.hash,
    _placeID.hash,
    _ref.hash,
    _pageID.hash,
    _video.hash,
    _shareUUID.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKShareVideoContent.class]) {
    return NO;
  }
  return [self isEqualToShareVideoContent:(FBSDKShareVideoContent *)object];
}

- (BOOL)isEqualToShareVideoContent:(FBSDKShareVideoContent *)content
{
  return (content
    && [FBSDKInternalUtility.sharedUtility object:_contentURL isEqualToObject:content.contentURL]
    && [FBSDKInternalUtility.sharedUtility object:_hashtag isEqualToObject:content.hashtag]
    && [FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:content.peopleIDs]
    && [FBSDKInternalUtility.sharedUtility object:_placeID isEqualToObject:content.placeID]
    && [FBSDKInternalUtility.sharedUtility object:_ref isEqualToObject:content.ref]
    && [FBSDKInternalUtility.sharedUtility object:_pageID isEqualToObject:content.pageID]
    && [FBSDKInternalUtility.sharedUtility object:_shareUUID isEqualToObject:content.shareUUID]
    && [FBSDKInternalUtility.sharedUtility object:_video isEqualToObject:content.video]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _contentURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SHARE_VIDEO_CONTENT_CONTENT_URL_KEY];
    _hashtag = [decoder decodeObjectOfClass:FBSDKHashtag.class forKey:FBSDK_SHARE_VIDEO_CONTENT_HASHTAG_KEY];
    _peopleIDs = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_SHARE_VIDEO_CONTENT_PEOPLE_IDS_KEY];
    _placeID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_VIDEO_CONTENT_PLACE_ID_KEY];
    _ref = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_VIDEO_CONTENT_REF_KEY];
    _pageID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_VIDEO_CONTENT_PAGE_ID_KEY];
    _video = [decoder decodeObjectOfClass:FBSDKShareVideo.class forKey:FBSDK_SHARE_VIDEO_CONTENT_VIDEO_KEY];
    _shareUUID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_VIDEO_CONTENT_UUID_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_contentURL forKey:FBSDK_SHARE_VIDEO_CONTENT_CONTENT_URL_KEY];
  [encoder encodeObject:_hashtag forKey:FBSDK_SHARE_VIDEO_CONTENT_HASHTAG_KEY];
  [encoder encodeObject:_peopleIDs forKey:FBSDK_SHARE_VIDEO_CONTENT_PEOPLE_IDS_KEY];
  [encoder encodeObject:_placeID forKey:FBSDK_SHARE_VIDEO_CONTENT_PLACE_ID_KEY];
  [encoder encodeObject:_ref forKey:FBSDK_SHARE_VIDEO_CONTENT_REF_KEY];
  [encoder encodeObject:_pageID forKey:FBSDK_SHARE_VIDEO_CONTENT_PAGE_ID_KEY];
  [encoder encodeObject:_video forKey:FBSDK_SHARE_VIDEO_CONTENT_VIDEO_KEY];
  [encoder encodeObject:_shareUUID forKey:FBSDK_SHARE_VIDEO_CONTENT_UUID_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKShareVideoContent *copy = [FBSDKShareVideoContent new];
  copy->_contentURL = [_contentURL copy];
  copy->_hashtag = [_hashtag copy];
  copy->_peopleIDs = [_peopleIDs copy];
  copy->_placeID = [_placeID copy];
  copy->_ref = [_ref copy];
  copy->_pageID = [_pageID copy];
  copy->_video = [_video copy];
  copy->_shareUUID = [_shareUUID copy];
  return copy;
}

@end
