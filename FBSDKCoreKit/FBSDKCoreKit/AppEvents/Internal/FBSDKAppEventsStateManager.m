/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAppEventsStateManager.h"

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppEventsState.h"
#import "FBSDKLogger.h"
#import "FBSDKUnarchiverProvider.h"

@interface FBSDKAppEventsStateManager ()
// A quick optimization to allow returning empty array if we know there are no persisted events.
@property (nonatomic, readwrite, assign) BOOL canSkipDiskCheck;
@end

@implementation FBSDKAppEventsStateManager

- (instancetype)init
{
  if ((self = [super init])) {
    _canSkipDiskCheck = NO;
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

- (void)clearPersistedAppEventsStates
{
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                         logEntry:@"FBSDKAppEvents Persist: Clearing"];
  [NSFileManager.defaultManager removeItemAtPath:[self filePath]
                                           error:NULL];
  self.canSkipDiskCheck = YES;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)persistAppEventsData:(FBSDKAppEventsState *)appEventsState
{
  NSString *msg = [NSString stringWithFormat:@"FBSDKAppEvents Persist: Writing %lu events", (unsigned long)appEventsState.events.count];
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                         logEntry:msg];

  if (!appEventsState.events.count) {
    return;
  }
  NSMutableArray *existingEvents = [NSMutableArray arrayWithArray:[self retrievePersistedAppEventsStates]];
  [FBSDKTypeUtility array:existingEvents addObject:appEventsState];

  [NSKeyedArchiver archiveRootObject:existingEvents toFile:[self filePath]];
  self.canSkipDiskCheck = NO;
}

- (NSArray<FBSDKAppEventsState *> *)retrievePersistedAppEventsStates;
{
  NSMutableArray *eventsStates = [NSMutableArray array];
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
                     (unsigned long)eventsStates.count,
                     (unsigned long)(eventsStates.count > 0 ? ((FBSDKAppEventsState *)[FBSDKTypeUtility array:eventsStates objectAtIndex:0]).events.count : 0)];
    [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorAppEvents
                           logEntry:msg];
    [self clearPersistedAppEventsStates];
  }
  return eventsStates;
}

#pragma clang diagnostic pop

#pragma mark - Private Helpers

- (NSString *)filePath
{
  return [FBSDKBasicUtility persistenceFilePath:@"com-facebook-sdk-AppEventsPersistedEvents.json"];
}

@end
