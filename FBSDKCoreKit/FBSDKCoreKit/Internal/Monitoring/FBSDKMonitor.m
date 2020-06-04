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
static const double FBSDKMonitorLogFlushIntervalInSeconds = 60;
static const double FBSDKMonitorLogFlushTimerTolerance = FBSDKMonitorLogFlushIntervalInSeconds / 3;

@interface FBSDKMonitor ()

@property (class, nonatomic, copy, readonly) NSMutableArray<id<FBSDKMonitorEntry>> *entries;
@property (class, nonatomic) FBSDKMonitorStore *store;

@end

@implementation FBSDKMonitor

static BOOL isMonitoringEnabled = NO;
static NSMutableArray<id<FBSDKMonitorEntry>> *_entries = nil;
static FBSDKMonitorStore *_store;
static NSTimer *_flushTimer;

#pragma mark - Public Methods

+ (void)enable
{
  if (isMonitoringEnabled) {
    return;
  }

  isMonitoringEnabled = YES;
  [self registerNotifications];
  [self startFlushTimer];
}

+ (void)record:(id<FBSDKMonitorEntry>)entry
{
  if (self.entries) {
    if (isMonitoringEnabled) {
      [FBSDKTypeUtility array:self.entries addObject:entry];

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

+ (void)startFlushTimer
{
  if (_flushTimer) {
    [_flushTimer invalidate];
    _flushTimer = nil;
  }

  _flushTimer = [NSTimer scheduledTimerWithTimeInterval:FBSDKMonitorLogFlushIntervalInSeconds
                                                 target:self.class
                                               selector:@selector(flush)
                                               userInfo:nil
                                                repeats:YES];

  // The timing of this is relatively unimportant as regards precision and a higher tolerance
  // allows the os run more efficiently and save power. They recommend 10 percent of the interval
  // but we're so generous we're gonna give 30 percent!
  _flushTimer.tolerance = FBSDKMonitorLogFlushTimerTolerance;
}

+ (void)stopFlushTimer
{
  if (_flushTimer) {
    [_flushTimer invalidate];
    _flushTimer = nil;
  }
}

+ (void)disable
{
  if (!isMonitoringEnabled) {
    return;
  }

  isMonitoringEnabled = NO;

  [self clearEntries];
  [self.store clear];
  [self unregisterNotifications];
  [self stopFlushTimer];
}

+ (void)flush
{
  if (self.entries.count > 0) {
    [FBSDKMonitorNetworker sendEntries:[self.entries copy]];
    [self clearEntries];
  }
}

+ (void)clearEntries
{
  [self.entries removeAllObjects];
}

@end
