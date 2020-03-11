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
  return [[self alloc] init];
}

+ (instancetype)testEntryWithName:(NSString *)name
{
  TestMonitorEntry *entry = [TestMonitorEntry testEntry];
  entry.name = name;

  return entry;
}

- (BOOL)isEqualToTestMonitorEntry:(TestMonitorEntry *)entry
{
  BOOL appIDsMatch = YES;
  BOOL namesMatch = YES;

  if (self.appID && entry.appID) {
    appIDsMatch = [self.appID isEqualToString:entry.appID];
  }

  if (self.name && entry.name) {
    namesMatch = [self.name isEqualToString:entry.name];
  }
  return appIDsMatch && namesMatch;
}

- (BOOL)isEqual:(id)other
{
  if (other == self) {
    return YES;
  }

  if (![other isKindOfClass:[FBSDKMonitorEntry class]]) {
    return NO;
  }

  return [self isEqualToTestMonitorEntry:other];
}

- (NSUInteger)hash
{
  return [self.appID hash] ^ [self.name hash];
}

- (NSDictionary *)toJSONDictionary
{
  return @{@"foo":@"bar"};
}

@end
