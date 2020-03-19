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

#import "FBSDKMethodUsageMonitorEntry.h"

static NSString * const FBSDKMethodUsageNameKey = @"event_name";
static NSString * const FBSDKMethodUsageParametersKey = @"parameters";

@implementation FBSDKMethodUsageMonitorEntry {
  SEL _method;
}

+ (instancetype)entryWithMethod:(SEL)method
{
  FBSDKMethodUsageMonitorEntry *entry = [[self alloc] init];
  if (entry) {
    entry->_method = method;
  }

  return entry;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder]) {
    NSString *methodName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKMethodUsageNameKey];
    _method = NSSelectorFromString(methodName);
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];

  NSString *methodName = NSStringFromSelector(_method);
  [encoder encodeObject:methodName forKey:FBSDKMethodUsageNameKey];
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:
                                     [super dictionaryRepresentation]];

  [dictionary setObject:NSStringFromSelector(_method) forKey:FBSDKMethodUsageNameKey];

  return dictionary;
}

@end
