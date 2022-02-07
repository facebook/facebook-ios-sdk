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
#import <FBSDKShareKit/_FBSDKShareUtility.h>

#import "FBSDKHashtag.h"

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
  [_FBSDKShareUtility assertCollection:peopleIDs ofClass:NSString.class name:@"peopleIDs"];
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
                       setObject:[_FBSDKShareUtility convertPhoto:_video.previewPhoto]
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
  if (![_FBSDKShareUtility validateRequiredValue:_video name:@"video" error:errorRef]) {
    return NO;
  }
  return [_video validateWithOptions:bridgeOptions error:errorRef];
}

@end
