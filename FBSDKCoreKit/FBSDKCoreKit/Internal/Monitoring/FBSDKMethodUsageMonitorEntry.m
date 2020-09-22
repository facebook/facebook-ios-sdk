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

static NSString *const FBSDKMethodUsageNameKey = @"event_name";
static NSString *const FBSDKMethodUsageClassKey = @"method_usage_class";

@implementation FBSDKMethodUsageMonitorEntry
{
  SEL _method;
  Class _class;
  NSString *_name;
}

+ (instancetype)entryFromClass:(Class)clazz withMethod:(SEL)method
{
  FBSDKMethodUsageMonitorEntry *entry = [[self alloc] init];
  if (entry) {
    entry->_method = method;
    entry->_class = clazz;
  }

  return entry;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  NSString *methodName = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKMethodUsageNameKey];
  NSString *className = [decoder decodeObjectOfClass:[NSString class] forKey:FBSDKMethodUsageClassKey];

  _method = NSSelectorFromString(methodName);
  _class = NSClassFromString(className);

  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  NSString *methodName = NSStringFromSelector(_method);
  NSString *className = NSStringFromClass(_class);

  [encoder encodeObject:methodName forKey:FBSDKMethodUsageNameKey];
  [encoder encodeObject:className forKey:FBSDKMethodUsageClassKey];
}

- (NSString *)name
{
  NSString *name = [NSString stringWithFormat:@"%@::%@", NSStringFromClass(_class), NSStringFromSelector(_method)];
  return [name copy];
}

- (NSDictionary *)dictionaryRepresentation
{
  return @{FBSDKMethodUsageNameKey : [self name]};
}

@end
