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

#import "FBSDKCoreKit+Internal.h"

static const int FBSDKMonitorLogThreshold = 100;

@interface FBSDKMonitor ()

@property (class, nonatomic, copy, readonly) NSMutableArray<id<FBSDKMonitorEntry>> *entries;

@end

@implementation FBSDKMonitor

static BOOL isMonitoringEnabled = NO;
static NSMutableArray<id<FBSDKMonitorEntry>> *_entries = nil;

+ (NSMutableArray<id<FBSDKMonitorEntry>> *)entries
{
  if (!_entries) {
    _entries = [NSMutableArray array];
  }

  return _entries;
}

+ (void)setEntries:(NSMutableArray<id<FBSDKMonitorEntry>> *)entries
{
  _entries = entries;
}

+ (void)enable
{
  isMonitoringEnabled = YES;
}

+ (void)disable
{
  isMonitoringEnabled = NO;
}

+ (void)flush
{
  [FBSDKMonitorNetworker sendEntries:self.entries];
  self.entries = [NSMutableArray array];
}

+ (void)record:(id<FBSDKMonitorEntry>)entry
{
  if (self.entries) {
    if (isMonitoringEnabled) {
      [self.entries addObject:entry];

      if (self.entries.count >= FBSDKMonitorLogThreshold) {
        [self flush];
      }
    }
  }
}

@end
