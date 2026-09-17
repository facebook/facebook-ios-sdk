/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FBSDKLogger.h"
#import "FBSDKUnarchiverProvider.h"

@interface FBSDKAppEventsStateManager ()
// A quick optimization to allow returning empty array if we know there are no persisted events.
@property (nonatomic, readwrite, assign) BOOL canSkipDiskCheck;
@property (nonatomic, strong) dispatch_queue_t persistQueue;
@end

@implementation FBSDKAppEventsStateManager

- (instancetype)init
{
  if ((self = [super init])) {
    _canSkipDiskCheck = NO;
    _persistQueue = dispatch_queue_create("com.facebook.sdk.AppEventsStateManager", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

+ (FBSDKAppEventsStateManager *)shared
{
  static dispatch_once_t nonce;
  static FBSDKAppEventsStateManager *instance = nil;

  dispatch_once(&nonce, ^{
    instance = [FBSDKAppEventsStateManager new];
  });
  return instance;
}

// dispatch_sync ensures callers see a consistent view of the file after any
// pending async persist completes. In practice, the blocking window is near-zero:
// persist runs on willResignActive (backgrounding) and retrieve runs on
// didBecomeActive (foregrounding), so the queue is drained by the time we get here.
- (void)clearPersistedAppEventsStates
{
  dispatch_sync(self.persistQueue, ^{
    [self _clearPersistedAppEventsStates];
  });
}

- (void)persistAppEventsData:(FBSDKAppEventsState *)appEventsState
{
  NSString *msg = [NSString stringWithFormat:@"FBSDKAppEvents Persist: Writing %lu events", (unsigned long)appEventsState.events.count];
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                         logEntry:msg];

  if (!appEventsState.events.count) {
    return;
  }

  // UIApplication.sharedApplication is unavailable in app extensions.
  // Use NSClassFromString so this code is safe if the SDK is ever linked
  // into an extension target.
  __block UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
  UIApplication *app = nil;
  Class uiAppClass = NSClassFromString(@"UIApplication");
  if (uiAppClass) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    app = [uiAppClass performSelector:NSSelectorFromString(@"sharedApplication")];
#pragma clang diagnostic pop
  }
  if (app) {
    taskID = [app beginBackgroundTaskWithExpirationHandler:^{
      [app endBackgroundTask:taskID];
      taskID = UIBackgroundTaskInvalid;
    }];
  }

  dispatch_async(self.persistQueue, ^{
    NSMutableArray<FBSDKAppEventsState *> *existingEvents = [NSMutableArray arrayWithArray:[self _retrievePersistedAppEventsStates]];
    [FBSDKTypeUtility array:existingEvents addObject:appEventsState];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [NSKeyedArchiver archiveRootObject:existingEvents toFile:[self filePath]];
#pragma clang diagnostic pop
    self.canSkipDiskCheck = NO;

    if (app && taskID != UIBackgroundTaskInvalid) {
      [app endBackgroundTask:taskID];
    }
  });
}

- (NSArray<FBSDKAppEventsState *> *)retrievePersistedAppEventsStates
{
  __block NSArray<FBSDKAppEventsState *> *result;
  dispatch_sync(self.persistQueue, ^{
    result = [self _retrievePersistedAppEventsStates];
  });
  return result;
}

#pragma mark - Queue-internal helpers (must be called on persistQueue)

- (void)_clearPersistedAppEventsStates
{
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                         logEntry:@"FBSDKAppEvents Persist: Clearing"];
  [NSFileManager.defaultManager removeItemAtPath:[self filePath]
                                           error:NULL];
  self.canSkipDiskCheck = YES;
}

- (NSArray<FBSDKAppEventsState *> *)_retrievePersistedAppEventsStates
{
  NSMutableArray<FBSDKAppEventsState *> *eventsStates = [NSMutableArray array];
  if (!self.canSkipDiskCheck) {
    NSData *data = [[NSData alloc] initWithContentsOfFile:[self filePath] options:NSDataReadingMappedIfSafe error:NULL];
    id<FBSDKObjectDecoding> unarchiver = [FBSDKUnarchiverProvider createSecureUnarchiverFor:data];
    @try {
      NSArray<FBSDKAppEventsState *> *retrievedEvents = [unarchiver decodeObjectOfClasses:
                                                         [NSSet setWithObjects:NSArray.class, FBSDKAppEventsState.class, NSDictionary.class, nil]
                                                                                   forKey:NSKeyedArchiveRootObjectKey];
      [eventsStates addObjectsFromArray:[FBSDKTypeUtility arrayValue:retrievedEvents]];
    } @catch (NSException *ex) {
      // ignore decoding exceptions from previous versions of the archive, etc
    }

    NSString *msg = [NSString stringWithFormat:@"FBSDKAppEvents Persist: Read %lu event states. First state has %lu events",
                     eventsStates.count,
                     ((FBSDKAppEventsState *)eventsStates.firstObject).events.count];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                           logEntry:msg];
    [self _clearPersistedAppEventsStates];
  }
  return eventsStates;
}


#pragma mark - Private Helpers

- (NSString *)filePath
{
  return [FBSDKBasicUtility persistenceFilePath:@"com-facebook-sdk-AppEventsPersistedEvents.json"];
}

@end
