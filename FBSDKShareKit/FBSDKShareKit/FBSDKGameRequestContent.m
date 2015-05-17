// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKGameRequestContent.h"

#import "FBSDKCoreKit+Internal.h"
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

- (void)setTo:(NSArray *)to
{
  [FBSDKShareUtility assertCollection:to ofClass:[NSString class] name:@"to"];
  if (![_to isEqual:to]) {
    _to = [to copy];
  }
}

- (void)setSuggestions:(NSArray *)suggestions
{
  [FBSDKShareUtility assertCollection:suggestions ofClass:[NSString class] name:@"suggestions"];
  if (![_suggestions isEqual:suggestions]) {
    _suggestions = [suggestions copy];
  }
}

#pragma mark - Equality

- (NSUInteger)hash
{
  NSUInteger subhashes[] = {
    [FBSDKMath hashWithInteger:_actionType],
    [_data hash],
    [FBSDKMath hashWithInteger:_filters],
    [_message hash],
    [_objectID hash],
    [_suggestions hash],
    [_title hash],
    [_to hash],
  };
  return [FBSDKMath hashWithIntegerArray:subhashes count:sizeof(subhashes) / sizeof(subhashes[0])];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[FBSDKGameRequestContent class]]) {
    return NO;
  }
  return [self isEqualToGameRequestContent:(FBSDKGameRequestContent *)object];
}

- (BOOL)isEqualToGameRequestContent:(FBSDKGameRequestContent *)content
{
  return (content &&
          _actionType == content.actionType &&
          _filters == content.filters &&
          [FBSDKInternalUtility object:_data isEqualToObject:content.data] &&
          [FBSDKInternalUtility object:_message isEqualToObject:content.message] &&
          [FBSDKInternalUtility object:_objectID isEqualToObject:content.objectID] &&
          [FBSDKInternalUtility object:_suggestions isEqualToObject:content.suggestions] &&
          [FBSDKInternalUtility object:_title isEqualToObject:content.title] &&
          [FBSDKInternalUtility object:_to isEqualToObject:content.to]);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  if ((self = [self init])) {
    _actionType = [decoder decodeIntegerForKey:FBSDK_APP_REQUEST_CONTENT_ACTION_TYPE_KEY];
    _data = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_DATA_KEY];
    _filters = [decoder decodeIntegerForKey:FBSDK_APP_REQUEST_CONTENT_FILTERS_KEY];
    _message = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_MESSAGE_KEY];
    _objectID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_OBJECT_ID_KEY];
    _suggestions = [decoder decodeObjectOfClass:[NSArray class] forKey:FBSDK_APP_REQUEST_CONTENT_SUGGESTIONS_KEY];
    _title = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APP_REQUEST_CONTENT_TITLE_KEY];
    _to = [decoder decodeObjectOfClass:[NSArray class] forKey:FBSDK_APP_REQUEST_CONTENT_TO_KEY];
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
  [encoder encodeObject:_suggestions forKey:FBSDK_APP_REQUEST_CONTENT_SUGGESTIONS_KEY];
  [encoder encodeObject:_title forKey:FBSDK_APP_REQUEST_CONTENT_TITLE_KEY];
  [encoder encodeObject:_to forKey:FBSDK_APP_REQUEST_CONTENT_TO_KEY];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  FBSDKGameRequestContent *copy = [[FBSDKGameRequestContent alloc] init];
  copy->_actionType = _actionType;
  copy->_data = [_data copy];
  copy->_filters = _filters;
  copy->_message = [_message copy];
  copy->_objectID = [_objectID copy];
  copy->_suggestions = [_suggestions copy];
  copy->_title = [_title copy];
  copy->_to = [_to copy];
  return copy;
}

@end
