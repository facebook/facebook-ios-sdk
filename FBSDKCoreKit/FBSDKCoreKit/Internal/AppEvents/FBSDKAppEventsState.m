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

#import "FBSDKAppEventsState.h"

#import "FBSDKInternalUtility.h"
#import "FBSDKMacros.h"

#define FBSDK_APPEVENTSTATE_ISIMPLICIT_KEY @"isImplicit"

#define FBSDK_APPEVENTSSTATE_MAX_EVENTS 1000

#define FBSDK_APPEVENTSSTATE_APPID_KEY @"appID"
#define FBSDK_APPEVENTSSTATE_EVENTS_KEY @"events"
#define FBSDK_APPEVENTSSTATE_NUMSKIPPED_KEY @"numSkipped"
#define FBSDK_APPEVENTSSTATE_TOKENSTRING_KEY @"tokenString"

@implementation FBSDKAppEventsState
{
  NSMutableArray *_mutableEvents;
  BOOL _containsExplicitEvent;
}

- (instancetype)init
{
  FBSDK_NOT_DESIGNATED_INITIALIZER(initWithToken:appID:);
  return [self initWithToken:nil appID:nil];
}

- (instancetype)initWithToken:(NSString *)tokenString appID:(NSString *)appID
{
  if ((self = [super init])) {
    _tokenString = [tokenString copy];
    _appID = [appID copy];
    _mutableEvents = [NSMutableArray array];
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FBSDKAppEventsState *copy = [[FBSDKAppEventsState allocWithZone:zone] initWithToken:_tokenString appID:_appID];
  if (copy) {
    [copy->_mutableEvents addObjectsFromArray:_mutableEvents];
    copy->_numSkipped = _numSkipped;
    copy->_containsExplicitEvent = _containsExplicitEvent;
  }
  return copy;
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  NSString *appID = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APPEVENTSSTATE_APPID_KEY];
  NSString *tokenString = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDK_APPEVENTSSTATE_TOKENSTRING_KEY];
  NSArray *events = [decoder decodeObjectOfClass:[NSArray class] forKey:FBSDK_APPEVENTSSTATE_EVENTS_KEY];
  NSUInteger numSkipped = [[decoder decodeObjectOfClass:[NSNumber class] forKey:FBSDK_APPEVENTSSTATE_NUMSKIPPED_KEY] unsignedIntegerValue];

  if ((self = [self initWithToken:tokenString appID:appID])) {
    _mutableEvents = [NSMutableArray arrayWithArray:events];
    _numSkipped = numSkipped;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_appID forKey:FBSDK_APPEVENTSSTATE_APPID_KEY];
  [encoder encodeObject:_tokenString forKey:FBSDK_APPEVENTSSTATE_TOKENSTRING_KEY];
  [encoder encodeObject:@(_numSkipped) forKey:FBSDK_APPEVENTSSTATE_NUMSKIPPED_KEY];
  [encoder encodeObject:_mutableEvents forKey:FBSDK_APPEVENTSSTATE_EVENTS_KEY];
}

#pragma mark - Implementation

- (NSArray *)events
{
  return [_mutableEvents copy];
}

- (void)addEventsFromAppEventState:(FBSDKAppEventsState *)appEventsState
{
  NSArray *toAdd = appEventsState->_mutableEvents;
  NSInteger excess = _mutableEvents.count + toAdd.count - FBSDK_APPEVENTSSTATE_MAX_EVENTS;
  if (excess > 0) {
    NSInteger range = FBSDK_APPEVENTSSTATE_MAX_EVENTS - _mutableEvents.count;
    toAdd = [toAdd subarrayWithRange:NSMakeRange(0, range)];
    _numSkipped += excess;
  }

  [_mutableEvents addObjectsFromArray:toAdd];
}

- (void)addEvent:(NSDictionary *)eventDictionary
      isImplicit:(BOOL)isImplicit {
  if (_mutableEvents.count >= FBSDK_APPEVENTSSTATE_MAX_EVENTS) {
    _numSkipped++;
  } else {
    if (!isImplicit) {
      _containsExplicitEvent = YES;
    }
    [_mutableEvents addObject:@{
                                @"event" : eventDictionary,
                                FBSDK_APPEVENTSTATE_ISIMPLICIT_KEY : @(isImplicit)
                                }];
  }
}

- (BOOL)areAllEventsImplicit
{
  return !_containsExplicitEvent;
}

- (BOOL)isCompatibleWithAppEventsState:(FBSDKAppEventsState *)appEventsState
{
  return ([self isCompatibleWithTokenString:appEventsState.tokenString appID:appEventsState.appID]);
}

- (BOOL)isCompatibleWithTokenString:(NSString *)tokenString appID:(NSString *)appID
{
  // token strings can be nil (e.g., no user token) but appIDs should not.
  BOOL tokenCompatible = ([self.tokenString isEqualToString:tokenString] ||
                          (self.tokenString == nil && tokenString == nil));
  return (tokenCompatible &&
          [self.appID isEqualToString:appID]);
}

- (NSString *)JSONStringForEvents:(BOOL)includeImplicitEvents
{
  NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:_mutableEvents.count];
  for (NSDictionary *eventAndImplicitFlag in _mutableEvents) {
    if (!includeImplicitEvents && [eventAndImplicitFlag[FBSDK_APPEVENTSTATE_ISIMPLICIT_KEY] boolValue]) {
      continue;
    }
    [events addObject:eventAndImplicitFlag[@"event"]];
  }

  return [FBSDKInternalUtility JSONStringForObject:events error:NULL invalidObjectHandler:NULL];
}
@end
