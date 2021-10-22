/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKGameRequestContent.h"

#import "FBSDKHasher.h"
#import "FBSDKShareConstants.h"
#import "FBSDKShareUtility.h"

#define FBSDK_APP_REQUEST_CONTENT_TO_KEY @"to"
#define FBSDK_APP_REQUEST_CONTENT_MESSAGE_KEY @"message"
#define FBSDK_APP_REQUEST_CONTENT_ACTION_TYPE_KEY @"actionType"
#define FBSDK_APP_REQUEST_CONTENT_OBJECT_ID_KEY @"objectID"
#define FBSDK_APP_REQUEST_CONTENT_FILTERS_KEY @"filters"
#define FBSDK_APP_REQUEST_CONTENT_SUGGESTIONS_KEY @"suggestions"
#define FBSDK_APP_REQUEST_CONTENT_DATA_KEY @"data"
#define FBSDK_APP_REQUEST_CONTENT_TITLE_KEY @"title"

@implementation FBSDKGameRequestContent

#pragma mark - Properties

- (void)setRecipients:(NSArray *)recipients
{
  [FBSDKShareUtility assertCollection:recipients ofClass:NSString.class name:@"recipients"];
  if (![_recipients isEqual:recipients]) {
    _recipients = [recipients copy];
  }
}

- (void)setRecipientSuggestions:(NSArray *)recipientSuggestions
{
  [FBSDKShareUtility assertCollection:recipientSuggestions ofClass:NSString.class name:@"recipientSuggestions"];
  if (![_recipientSuggestions isEqual:recipientSuggestions]) {
    _recipientSuggestions = [recipientSuggestions copy];
  }
}

- (NSArray *)suggestions
{
  return self.recipientSuggestions;
}

- (void)setSuggestions:(NSArray *)suggestions
{
  self.recipientSuggestions = suggestions;
}

- (NSArray *)to
{
  return self.recipients;
}

- (void)setTo:(NSArray *)to
{
  self.recipients = to;
}

#pragma mark - FBSDKSharingValidation

- (BOOL)validateWithOptions:(FBSDKShareBridgeOptions)bridgeOptions error:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKShareUtility validateRequiredValue:_message name:@"message" error:errorRef]) {
    return NO;
  }
  BOOL mustHaveobjectID = _actionType == FBSDKGameRequestActionTypeSend
  || _actionType == FBSDKGameRequestActionTypeAskFor;
  BOOL hasobjectID = _objectID.length > 0;
  if (mustHaveobjectID ^ hasobjectID) {
    if (errorRef != NULL) {
      NSString *message = @"The objectID is required when the actionType is either send or askfor.";
      *errorRef = [FBSDKError requiredArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                         name:@"objectID"
                                                      message:message];
    }
    return NO;
  }
  BOOL hasTo = _recipients.count > 0;
  BOOL hasFilters = _filters != FBSDKGameRequestFilterNone;
  BOOL hasSuggestions = _recipientSuggestions.count > 0;
  if (hasTo && hasFilters) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify to and filters at the same time.";
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"recipients"
                                                       value:_recipients
                                                     message:message];
    }
    return NO;
  }
  if (hasTo && hasSuggestions) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify to and suggestions at the same time.";
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"recipients"
                                                       value:_recipients
                                                     message:message];
    }
    return NO;
  }

  if (hasFilters && hasSuggestions) {
    if (errorRef != NULL) {
      NSString *message = @"Cannot specify filters and suggestions at the same time.";
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"recipientSuggestions"
                                                       value:_recipientSuggestions
                                                     message:message];
    }
    return NO;
  }

  if (_data.length > 255) {
    if (errorRef != NULL) {
      NSString *message = @"The data cannot be longer than 255 characters";
      *errorRef = [FBSDKError invalidArgumentErrorWithDomain:FBSDKShareErrorDomain
                                                        name:@"data"
                                                       value:_data
                                                     message:message];
    }
    return NO;
  }

  if (errorRef != NULL) {
    *errorRef = nil;
  }

  return [FBSDKShareUtility validateArgumentWithName:@"actionType"
                                               value:_actionType
                                                isIn:@[@(FBSDKGameRequestActionTypeNone),
                                                       @(FBSDKGameRequestActionTypeSend),
                                                       @(FBSDKGameRequestActionTypeAskFor),
                                                       @(FBSDKGameRequestActionTypeTurn),
                                                       @(FBSDKGameRequestActionTypeInvite)]
                                               error:errorRef]
  && [FBSDKShareUtility validateArgumentWithName:@"filters"
                                           value:_filters
                                            isIn:@[@(FBSDKGameRequestFilterNone),
                                                   @(FBSDKGameRequestFilterAppUsers),
                                                   @(FBSDKGameRequestFilterAppNonUsers),
                                                   @(FBSDKGameRequestFilterEverybody)]
                                           error:errorRef];
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    [FBSDKHasher hashWithInteger:_actionType],
    _data.hash,
    [FBSDKHasher hashWithInteger:_filters],
    _message.hash,
    _objectID.hash,
    _recipientSuggestions.hash,
    _title.hash,
    _recipients.hash,
  };
  return [FBSDKHasher hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:FBSDKGameRequestContent.class]) {
    return NO;
  }
  return [self isEqualToGameRequestContent:(FBSDKGameRequestContent *)object];
}

- (BOOL)isEqualToGameRequestContent:(FBSDKGameRequestContent *)content
{
  return (content
    && _actionType == content.actionType
    && _filters == content.filters
    && [FBSDKInternalUtility.sharedUtility object:_data isEqualToObject:content.data]
    && [FBSDKInternalUtility.sharedUtility object:_message isEqualToObject:content.message]
    && [FBSDKInternalUtility.sharedUtility object:_objectID isEqualToObject:content.objectID]
    && [FBSDKInternalUtility.sharedUtility object:_recipientSuggestions isEqualToObject:content.recipientSuggestions]
    && [FBSDKInternalUtility.sharedUtility object:_title isEqualToObject:content.title]
    && [FBSDKInternalUtility.sharedUtility object:_recipients isEqualToObject:content.recipients]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _actionType = [decoder decodeIntegerForKey:FBSDK_APP_REQUEST_CONTENT_ACTION_TYPE_KEY];
    _data = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_REQUEST_CONTENT_DATA_KEY];
    _filters = [decoder decodeIntegerForKey:FBSDK_APP_REQUEST_CONTENT_FILTERS_KEY];
    _message = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_REQUEST_CONTENT_MESSAGE_KEY];
    _objectID = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_REQUEST_CONTENT_OBJECT_ID_KEY];
    _recipientSuggestions = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_APP_REQUEST_CONTENT_SUGGESTIONS_KEY];
    _title = [decoder decodeObjectOfClass:NSString.class forKey:FBSDK_APP_REQUEST_CONTENT_TITLE_KEY];
    _recipients = [decoder decodeObjectOfClass:NSArray.class forKey:FBSDK_APP_REQUEST_CONTENT_TO_KEY];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeInteger:_actionType forKey:FBSDK_APP_REQUEST_CONTENT_ACTION_TYPE_KEY];
  [encoder encodeObject:_data forKey:FBSDK_APP_REQUEST_CONTENT_DATA_KEY];
  [encoder encodeInteger:_filters forKey:FBSDK_APP_REQUEST_CONTENT_FILTERS_KEY];
  [encoder encodeObject:_message forKey:FBSDK_APP_REQUEST_CONTENT_MESSAGE_KEY];
  [encoder encodeObject:_objectID forKey:FBSDK_APP_REQUEST_CONTENT_OBJECT_ID_KEY];
  [encoder encodeObject:_recipientSuggestions forKey:FBSDK_APP_REQUEST_CONTENT_SUGGESTIONS_KEY];
  [encoder encodeObject:_title forKey:FBSDK_APP_REQUEST_CONTENT_TITLE_KEY];
  [encoder encodeObject:_recipients forKey:FBSDK_APP_REQUEST_CONTENT_TO_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKGameRequestContent *copy = [FBSDKGameRequestContent new];
  copy->_actionType = _actionType;
  copy->_data = [_data copy];
  copy->_filters = _filters;
  copy->_message = [_message copy];
  copy->_objectID = [_objectID copy];
  copy->_recipientSuggestions = [_recipientSuggestions copy];
  copy->_title = [_title copy];
  copy->_recipients = [_recipients copy];
  return copy;
}

@end

#endif
