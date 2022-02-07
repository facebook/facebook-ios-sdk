/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareMediaContent.h"

#import <FBSDKShareKit/FBSDKShareErrorDomain.h>
#import <FBSDKShareKit/_FBSDKShareUtility.h>

#import "FBSDKHashtag.h"
#import "FBSDKSharePhoto.h"
#import "FBSDKShareVideo.h"

@implementation FBSDKShareMediaContent

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
  [_FBSDKShareUtility assertCollection:peopleIDs ofClass:NSString.class name:@"peopleIDs"];
  if (![FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:peopleIDs]) {
    _peopleIDs = [peopleIDs copy];
  }
}

- (void)setMedia:(NSArray<id<FBSDKShareMedia>> *)media
{
  [_FBSDKShareUtility assertCollection:media ofClassStrings:@[NSStringFromClass(FBSDKSharePhoto.class), NSStringFromClass(FBSDKShareVideo.class)] name:@"media"];
  if (![FBSDKInternalUtility.sharedUtility object:_media isEqualToObject:media]) {
    _media = [media copy];
  }
}

#pragma mark - FBSDKSharingContent

- (NSDictionary<NSString *, id> *)addParameters:(NSDictionary<NSString *, id> *)existingParameters
                                  bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
{
  // FBSDKShareMediaContent is currently available via the Share extension only (thus no parameterization implemented at this time)
  return existingParameters;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (![_FBSDKShareUtility validateArray:_media minCount:1 maxCount:20 name:@"photos" error:errorRef]) {
    return NO;
  }
  int videoCount = 0;
  for (id media in _media) {
    if ([media isKindOfClass:FBSDKSharePhoto.class]) {
      FBSDKSharePhoto *photo = (FBSDKSharePhoto *)media;
      if (![photo validateWithOptions:bridgeOptions error:NULL]) {
        if (errorRef != NULL) {
          id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
          *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                              name:@"media"
                                                             value:media
                                                           message:@"photos must have UIImages"
                                                   underlyingError:nil];
        }
        return NO;
      }
    } else if ([media isKindOfClass:FBSDKShareVideo.class]) {
      if (videoCount > 0) {
        if (errorRef != NULL) {
          id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
          *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                              name:@"media"
                                                             value:media
                                                           message:@"Only 1 video is allowed"
                                                   underlyingError:nil];
          return NO;
        }
      }
      videoCount++;
      FBSDKShareVideo *video = (FBSDKShareVideo *)media;
      if (![_FBSDKShareUtility validateRequiredValue:video name:@"video" error:errorRef]) {
        return NO;
      }
      if (![video validateWithOptions:bridgeOptions error:errorRef]) {
        return NO;
      }
    } else {
      if (errorRef != NULL) {
        id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];
        *errorRef = [errorFactory invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                            name:@"media"
                                                           value:media
                                                         message:@"Only FBSDKSharePhoto and FBSDKShareVideo are allowed in `media` property"
                                                 underlyingError:nil];
      }
      return NO;
    }
  }
  return YES;
}

@end
