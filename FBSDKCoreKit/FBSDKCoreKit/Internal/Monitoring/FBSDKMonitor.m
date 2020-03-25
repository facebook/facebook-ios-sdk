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
@property (class, nonatomic) FBSDKMonitorStore *store;

@end

@implementation FBSDKMonitor

static BOOL isMonitoringEnabled = NO;
static NSMutableArray<id<FBSDKMonitorEntry>> *_entries = nil;
static FBSDKMonitorStore *_store;

#pragma mark - Public Methods

+ (void)enable
{
  isMonitoringEnabled = YES;
  [self registerNotifications];
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

#pragma mark - Private Methods

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

+ (FBSDKMonitorStore *)store
{
  if (!_store) {
    NSString *filename = [NSString stringWithFormat:@"%@_", NSBundle.mainBundle.bundleIdentifier];
    _store = [[FBSDKMonitorStore alloc] initWithFilename:filename];
  }

  return _store;
}

+ (void)setStore:(FBSDKMonitorStore *)store
{
  _store = store;
}

+ (void)registerNotifications
{
  [[NSNotificationCenter defaultCenter]
   addObserver:[self class]
   selector:@selector(applicationMovingFromActiveStateOrTerminating)
   name:UIApplicationWillResignActiveNotification
   object:NULL];

  [[NSNotificationCenter defaultCenter]
   addObserver:[self class]
   selector:@selector(applicationMovingFromActiveStateOrTerminating)
   name:UIApplicationWillTerminateNotification
   object:NULL];

  [[NSNotificationCenter defaultCenter]
   addObserver:[self class]
   selector:@selector(applicationDidBecomeActive)
   name:UIApplicationDidBecomeActiveNotification
   object:NULL];
}

+ (void)unregisterNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver: [self class]];
}

+ (void)applicationDidBecomeActive
{
  // fetch entries from store and send them to server
  if (self.entries && self.store) {
    [self.entries addObjectsFromArray:[self.store retrieveEntries] ?: @[]];

    if (self.entries.count > 0) {
      [self flush];
    }
  }
}

+ (void)applicationMovingFromActiveStateOrTerminating
{
  // save entries to store
  if ((self.entries && self.entries.count > 0) && self.store) {
    [self.store persist:self.entries];
  }
}

+ (void)disable
{
  isMonitoringEnabled = NO;

  [self clearEntries];
  [self.store clear];
  [self unregisterNotifications];
}

+ (void)flush
{
  [FBSDKMonitorNetworker sendEntries:[self.entries copy]];
  [self clearEntries];
}

+ (void)clearEntries
{
  [self.entries removeAllObjects];
}

@end
