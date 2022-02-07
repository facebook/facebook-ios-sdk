/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKAppInviteContent.h"

#import <FBSDKShareKit/_FBSDKShareUtility.h>

@implementation FBSDKAppInviteContent

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
  return ([_FBSDKShareUtility validateNetworkURL:_appLinkURL name:@"appLinkURL" error:errorRef]
    && [_FBSDKShareUtility validateNetworkURL:_appInvitePreviewImageURL name:@"appInvitePreviewImageURL" error:errorRef]
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

@end

#endif
