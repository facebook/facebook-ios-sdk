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

#import "FBSDKPerformanceMonitorEntry.h"

#import "FBSDKInternalUtility.h"

static NSString *const FBSDKPerformanceNameKey = @"event_name";
static NSString *const FBSDKPerformanceStartTimeKey = @"time_start";
static NSString *const FBSDKPerformanceEndTimeKey = @"time_end";
static NSString *const FBSDKPerformanceTimeSpentKey = @"time_spent";

@implementation FBSDKPerformanceMonitorEntry
{
  NSString *_name;
  NSDate *_startTime;
  NSDate *_endTime;
}

+ (instancetype)entryWithName:(NSString *)name startTime:(NSDate *)startTime endTime:(NSDate *)endTime
{
  if ([endTime timeIntervalSinceDate:startTime] <= 0) {
    return nil;
  }

  FBSDKPerformanceMonitorEntry *entry = [[self alloc] init];
  if (entry) {
    entry->_name = name;
    entry->_startTime = startTime;
    entry->_endTime = endTime;
  }

  return entry;
}

- (NSString *)name
{
  return [_name copy];
}

- (void)encodeWithCoder:(nonnull NSCoder *)encoder
{
  if (_name && _startTime && _endTime) {
    [encoder encodeObject:_name forKey:FBSDKPerformanceNameKey];
    [encoder encodeObject:_startTime forKey:FBSDKPerformanceStartTimeKey];
    [encoder encodeObject:_endTime forKey:FBSDKPerformanceEndTimeKey];
  }
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)decoder
{
  _name = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKPerformanceNameKey];
  _startTime = [decoder decodeObjectOfClass:[NSDate class] forKey:FBSDKPerformanceStartTimeKey];
  _endTime = [decoder decodeObjectOfClass:[NSDate class] forKey:FBSDKPerformanceEndTimeKey];

  if (_name && _startTime && _endTime) {
    return self;
  }

  return nil;
}

- (nonnull NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  [FBSDKTypeUtility dictionary:dict setObject:_name
                        forKey:FBSDKPerformanceNameKey];
  [FBSDKTypeUtility dictionary:dict
                     setObject:@([_startTime timeIntervalSince1970])
                        forKey:FBSDKPerformanceStartTimeKey];
  [FBSDKTypeUtility dictionary:dict
                     setObject:@([_endTime timeIntervalSinceDate:_startTime])
                        forKey:FBSDKPerformanceTimeSpentKey];

  return dict;
}

@end
