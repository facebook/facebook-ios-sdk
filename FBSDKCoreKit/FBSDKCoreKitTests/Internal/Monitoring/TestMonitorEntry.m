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

#import "TestMonitorEntry.h"

@implementation TestMonitorEntry

+ (instancetype)testEntry
{
  TestMonitorEntry *entry = [[self alloc] init];
  entry.name = @"testEntry";

  return entry;
}

+ (instancetype)testEntryWithName:(NSString *)name
{
  TestMonitorEntry *entry = [TestMonitorEntry testEntry];
  entry.name = name;

  return entry;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.name forKey:@"name"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  self.name = [decoder decodeObjectOfClass:[NSString class] forKey:@"name"];

  return self;
}

- (NSDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *tmp = [NSMutableDictionary dictionary];

  [tmp setObject:self.name forKey:@"name"];

  return tmp;
}

- (BOOL)isEqualToTestMonitorEntry:(TestMonitorEntry *)entry
{
  if (self.name && entry.name) {
    return [self.name isEqualToString:entry.name];
  }

  return NO;
}

- (BOOL)isEqual:(id)other
{
  if (other == self) {
    return YES;
  }

  if (![other conformsToProtocol:@protocol(FBSDKMonitorEntry)]) {
    return NO;
  }

  return [self isEqualToTestMonitorEntry:other];
}

- (NSUInteger)hash
{
  return [self.name hash];
}


@end
