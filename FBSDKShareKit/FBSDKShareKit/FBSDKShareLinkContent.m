/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKShareLinkContent.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKHasher.h"
#import "FBSDKHashtag.h"
#import "FBSDKShareUtility.h"

#define FBSDK_SHARE_STATUS_CONTENT_CONTENT_URL_KEY @"contentURL"
#define FBSDK_SHARE_STATUS_CONTENT_HASHTAG_KEY @"hashtag"
#define FBSDK_SHARE_STATUS_CONTENT_PEOPLE_IDS_KEY @"peopleIDs"
#define FBSDK_SHARE_STATUS_CONTENT_PLACE_ID_KEY @"placeID"
#define FBSDK_SHARE_STATUS_CONTENT_REF_KEY @"ref"
#define FBSDK_SHARE_STATUS_CONTENT_PAGE_ID_KEY @"pageID"
#define FBSDK_SHARE_STATUS_CONTENT_QUOTE_TEXT_KEY @"quote"
#define FBSDK_SHARE_STATUS_CONTENT_UUID_KEY @"uuid"

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
  return [FBSDKShareUtility validateNetworkURL:_contentURL name:@"contentURL" error:errorRef];
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
    _quote.hash,
    _shareUUID.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKShareLinkContent.class]) {
    return NO;
  }
  return [self isEqualToShareLinkContent:(FBSDKShareLinkContent *)object];
}

- (BOOL)isEqualToShareLinkContent:(FBSDKShareLinkContent *)content
{
  return (content
    && [FBSDKInternalUtility.sharedUtility object:_contentURL isEqualToObject:content.contentURL]
    && [FBSDKInternalUtility.sharedUtility object:_hashtag isEqualToObject:content.hashtag]
    && [FBSDKInternalUtility.sharedUtility object:_peopleIDs isEqualToObject:content.peopleIDs]
    && [FBSDKInternalUtility.sharedUtility object:_placeID isEqualToObject:content.placeID]
    && [FBSDKInternalUtility.sharedUtility object:_ref isEqualToObject:content.ref]
    && [FBSDKInternalUtility.sharedUtility object:_pageID isEqualToObject:content.pageID]
    && [FBSDKInternalUtility.sharedUtility object:_shareUUID isEqualToObject:content.shareUUID])
  && [FBSDKInternalUtility.sharedUtility object:_quote isEqualToObject:content.quote];
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _contentURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_SHARE_STATUS_CONTENT_CONTENT_URL_KEY];
    _hashtag = [decoder decodeObjectOfClass:FBSDKHashtag.class forKey:FBSDK_SHARE_STATUS_CONTENT_HASHTAG_KEY];
    _peopleIDs = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_SHARE_STATUS_CONTENT_PEOPLE_IDS_KEY];
    _placeID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_STATUS_CONTENT_PLACE_ID_KEY];
    _ref = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_STATUS_CONTENT_REF_KEY];
    _pageID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_STATUS_CONTENT_PAGE_ID_KEY];
    _quote = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_STATUS_CONTENT_QUOTE_TEXT_KEY];
    _shareUUID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_SHARE_STATUS_CONTENT_UUID_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_contentURL forKey:FBSDK_SHARE_STATUS_CONTENT_CONTENT_URL_KEY];
  [encoder encodeObject:_hashtag forKey:FBSDK_SHARE_STATUS_CONTENT_HASHTAG_KEY];
  [encoder encodeObject:_peopleIDs forKey:FBSDK_SHARE_STATUS_CONTENT_PEOPLE_IDS_KEY];
  [encoder encodeObject:_placeID forKey:FBSDK_SHARE_STATUS_CONTENT_PLACE_ID_KEY];
  [encoder encodeObject:_ref forKey:FBSDK_SHARE_STATUS_CONTENT_REF_KEY];
  [encoder encodeObject:_pageID forKey:FBSDK_SHARE_STATUS_CONTENT_PAGE_ID_KEY];
  [encoder encodeObject:_quote forKey:FBSDK_SHARE_STATUS_CONTENT_QUOTE_TEXT_KEY];
  [encoder encodeObject:_shareUUID forKey:FBSDK_SHARE_STATUS_CONTENT_UUID_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKShareLinkContent *copy = [FBSDKShareLinkContent new];
  copy->_contentURL = [_contentURL copy];
  copy->_hashtag = [_hashtag copy];
  copy->_peopleIDs = [_peopleIDs copy];
  copy->_placeID = [_placeID copy];
  copy->_ref = [_ref copy];
  copy->_pageID = [_pageID copy];
  copy->_quote = [_quote copy];
  copy->_shareUUID = [_shareUUID copy];
  return copy;
}

@end
