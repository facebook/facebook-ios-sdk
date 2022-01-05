/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppInviteContent.h"

#import "FBSDKHasher.h"
#import "FBSDKShareUtility.h"

#define FBSDK_APP_INVITE_CONTENT_APP_LINK_URL_KEY @"appLinkURL"
#define FBSDK_APP_INVITE_CONTENT_PREVIEW_IMAGE_KEY @"previewImage"
#define FBSDK_APP_INVITE_CONTENT_PROMO_CODE_KEY @"promoCode"
#define FBSDK_APP_INVITE_CONTENT_PROMO_TEXT_KEY @"promoText"
#define FBSDK_APP_INVITE_CONTENT_DESTINATION_KEY @"destination"

@implementation FBSDKAppInviteContent

// This exists because you cannot deprecate a method that has never been implemented.
// You should not be able to create app invite content without an app link URL.
// This preserves the now-deprecated behavior and should be removed as soon as possible.
+ (instancetype)new
{
  return [[self alloc] init];
}

// This exists because you cannot deprecate a method that has never been implemented.
// You should not be able to create app invite content without an app link URL.
// This preserves the now-deprecated behavior and should be removed as soon as possible.
- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithAppLinkURL:(nonnull NSURL *)appLinkURL
{
  if ((self = [super init])) {
    _appLinkURL = appLinkURL;
  }
  return self;
}

- (NSURL *)previewImageURL
{
  return self.appInvitePreviewImageURL;
}

- (void)setPreviewImageURL:(NSURL *)previewImageURL
{
  self.appInvitePreviewImageURL = previewImageURL;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  return ([FBSDKShareUtility validateRequiredValue:_appLinkURL name:@"appLinkURL" error:errorRef]
    && [FBSDKShareUtility validateNetworkURL:_appLinkURL name:@"appLinkURL" error:errorRef]
    && [FBSDKShareUtility validateNetworkURL:_appInvitePreviewImageURL name:@"appInvitePreviewImageURL" error:errorRef]
    && [self _validatePromoCodeWithError:errorRef]);
}

- (BOOL)_validatePromoCodeWithError:(NSError *__autoreleasing *)errorRef
{
  if (_promotionText.length > 0 || _promotionCode.length > 0) {
    NSMutableCharacterSet *alphanumericWithSpaces = NSMutableCharacterSet.alphanumericCharacterSet;
    [alphanumericWithSpaces formUnionWithCharacterSet:NSCharacterSet.whitespaceCharacterSet];

    id<FBSDKErrorCreating> errorFactory = [FBSDKErrorFactory new];

    // Check for validity of promo text and promo code.
    if (!(_promotionText.length > 0 && _promotionText.length <= 80)) {
      if (errorRef != NULL) {
        NSString *message = @"Invalid value for promotionText, promotionText has to be between 1 and 80 characters long.";
        *errorRef = [errorFactory invalidArgumentErrorWithName:@"promotionText"
                                                         value:_promotionText
                                                       message:message
                                               underlyingError:nil];
      }
      return NO;
    }

    if (!(_promotionCode.length <= 10)) {
      if (errorRef != NULL) {
        NSString *message = @"Invalid value for promotionCode, promotionCode has to be between 0 and 10 characters long and is required when promoCode is set.";
        *errorRef = [errorFactory invalidArgumentErrorWithName:@"promotionCode"
                                                         value:_promotionCode
                                                       message:message
                                               underlyingError:nil];
      }
      return NO;
    }

    if ([_promotionText rangeOfCharacterFromSet:alphanumericWithSpaces.invertedSet].location != NSNotFound) {
      if (errorRef != NULL) {
        NSString *message = @"Invalid value for promotionText, promotionText can contain only alphanumeric characters and spaces.";
        *errorRef = [errorFactory invalidArgumentErrorWithName:@"promotionText"
                                                         value:_promotionText
                                                       message:message
                                               underlyingError:nil];
      }
      return NO;
    }

    if (_promotionCode.length > 0 && [_promotionCode rangeOfCharacterFromSet:alphanumericWithSpaces.invertedSet].location != NSNotFound) {
      if (errorRef != NULL) {
        NSString *message = @"Invalid value for promotionCode, promotionCode can contain only alphanumeric characters and spaces.";
        *errorRef = [errorFactory invalidArgumentErrorWithName:@"promotionCode"
                                                         value:_promotionCode
                                                       message:message
                                               underlyingError:nil];
      }
      return NO;
    }
  }

  if (errorRef != NULL) {
    *errorRef = nil;
  }

  return YES;
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    _appLinkURL.hash,
    _appInvitePreviewImageURL.hash,
    _promotionCode.hash,
    _promotionText.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKAppInviteContent.class]) {
    return NO;
  }
  return [self isEqualToAppInviteContent:(FBSDKAppInviteContent *)object];
}

- (BOOL)isEqualToAppInviteContent:(FBSDKAppInviteContent *)content
{
  return (content
    && [FBSDKInternalUtility.sharedUtility object:_appLinkURL isEqualToObject:content.appLinkURL]
    && [FBSDKInternalUtility.sharedUtility object:_appInvitePreviewImageURL isEqualToObject:content.appInvitePreviewImageURL]
    && [FBSDKInternalUtility.sharedUtility object:_promotionText isEqualToObject:content.promotionText]
    && [FBSDKInternalUtility.sharedUtility object:_promotionCode isEqualToObject:content.promotionText]
    && _destination == content.destination
  );
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSURL *appLinkURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_APP_INVITE_CONTENT_APP_LINK_URL_KEY];
  if (appLinkURL && (self = [self initWithAppLinkURL:appLinkURL])) {
    _appInvitePreviewImageURL = [decoder decodeObjectOfClass:NSURL.class forKey:FBSDK_APP_INVITE_CONTENT_PREVIEW_IMAGE_KEY];
    _promotionCode = [decoder decodeObjectOfClass:NSString.class forKey:
                      FBSDK_APP_INVITE_CONTENT_PROMO_CODE_KEY];
    _promotionText = [decoder decodeObjectOfClass:NSString.class forKey:
                      FBSDK_APP_INVITE_CONTENT_PROMO_TEXT_KEY];
    _destination = [decoder decodeIntegerForKey:
                    FBSDK_APP_INVITE_CONTENT_DESTINATION_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_appLinkURL forKey:FBSDK_APP_INVITE_CONTENT_APP_LINK_URL_KEY];
  [encoder encodeObject:_appInvitePreviewImageURL forKey:FBSDK_APP_INVITE_CONTENT_PREVIEW_IMAGE_KEY];
  [encoder encodeObject:_promotionCode forKey:FBSDK_APP_INVITE_CONTENT_PROMO_CODE_KEY];
  [encoder encodeObject:_promotionText forKey:FBSDK_APP_INVITE_CONTENT_PROMO_TEXT_KEY];
  [encoder encodeInt:(int)_destination forKey:FBSDK_APP_INVITE_CONTENT_DESTINATION_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKAppInviteContent *copy = [[FBSDKAppInviteContent alloc] initWithAppLinkURL:[_appLinkURL copy]];
  copy->_appInvitePreviewImageURL = [_appInvitePreviewImageURL copy];
  copy->_promotionText = [_promotionText copy];
  copy->_promotionCode = [_promotionCode copy];
  copy->_destination = _destination;
  return copy;
}

@end

#endif
