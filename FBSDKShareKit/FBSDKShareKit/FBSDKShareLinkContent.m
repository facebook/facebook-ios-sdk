/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareLinkContent.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <FBSDKShareKit/_FBSDKShareUtility.h>

#import "FBSDKHashtag.h"

@implementation FBSDKShareLinkContent

#pragma mark - Properties

@synthesize contentURL = _contentURL;
@synthesize hashtag = _hashtag;
@synthesize peopleIDs = _peopleIDs;
@synthesize placeID = _placeID;
@synthesize ref = _ref;
@synthesize pageID = _pageID;
@synthesize quote = _quote;
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

  [FBSDKTypeUtility dictionary:updatedParameters setObject:_contentURL forKey:@"link"];
  [FBSDKTypeUtility dictionary:updatedParameters setObject:_quote forKey:@"quote"];

  /**
   Pass link parameter as "messenger_link" due to versioning requirements for message dialog flow.
   We will only use the new share flow we developed if messenger_link is present, not link.
   */
  [FBSDKTypeUtility dictionary:updatedParameters setObject:_contentURL forKey:@"messenger_link"];

  return updatedParameters;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  return [_FBSDKShareUtility validateNetworkURL:_contentURL name:@"contentURL" error:errorRef];
}

@end
