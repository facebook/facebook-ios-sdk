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

#import "FBSDKTestCoder.h"

@implementation FBSDKTestCoder

- (instancetype)init
{
  if (self = [super init]) {
    _encodedObject = [NSMutableDictionary dictionary];
    _decodedObject = [NSMutableDictionary dictionary];
  }

  return self;
}

- (void)encodeObject:(id)object forKey:(NSString *)key
{
  self.encodedObject[key] = object;
}

- (void)encodeBool:(BOOL)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithBool:value];
  self.encodedObject[key] = converted;
}

- (void)encodeDouble:(double)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithDouble:value];
  self.encodedObject[key] = converted;
}

- (void)encodeInteger:(NSInteger)value forKey:(NSString *)key
{
  NSNumber *converted = [NSNumber numberWithInteger:value];
  self.encodedObject[key] = converted;
}

- (id)decodeObjectOfClass:(Class)aClass forKey:(NSString *)key
{
  self.decodedObject[key] = aClass;

  return key;
}

- (id)decodeObjectOfClasses:(NSSet<Class> *)classes forKey:(NSString *)key
{
  self.decodedObject[key] = classes;

  return key;
}

- (BOOL)decodeBoolForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeBoolForKey";

  return YES;
}

- (double)decodeDoubleForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeDoubleForKey";

  return 1;
}

- (NSInteger)decodeIntegerForKey:(NSString *)key
{
  self.decodedObject[key] = @"decodeIntegerForKey";

  return 1;
}

@end
