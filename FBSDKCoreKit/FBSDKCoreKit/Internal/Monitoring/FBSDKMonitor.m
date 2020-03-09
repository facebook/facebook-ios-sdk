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

#import "FBSDKMonitor.h"

#import "FBSDKFeatureManager.h"
#import "FBSDKCoreKit+Internal.h"

@interface FBSDKMonitor ()

@property (nonatomic) NSMutableArray<FBSDKMonitorEntry *> *entries;

+ (FBSDKMonitor *)shared;
- (void)record:(FBSDKMonitorEntry *)entry;

@end

@implementation FBSDKMonitor

static BOOL isMonitoringEnabled = NO;

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.entries = [NSMutableArray array];
  }
  return self;
}

+ (FBSDKMonitor *)shared
{
  static FBSDKMonitor *sharedInstance = nil;

  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    sharedInstance = [self new];
  });

  return sharedInstance;
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
  self.shared.entries = [NSMutableArray array];
}

+ (void)record:(FBSDKMonitorEntry *)entry
{
  [FBSDKMonitor.shared record:entry];
}

- (void)record:(FBSDKMonitorEntry *)entry
{
  // need to dispatch to the background immediately
  // encode and store entry in local entries array
  // do logic to see if needs to flush
  // potentially invoke networker

  if (isMonitoringEnabled) {
    [self.entries addObject:entry];
  }
}

+ (NSArray<NSString *> *)entries
{
  return [self.shared.entries copy];
}

@end
