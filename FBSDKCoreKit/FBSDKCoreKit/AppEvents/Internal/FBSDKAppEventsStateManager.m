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

#import "FBSDKAppEventsStateManager.h"

#import <Foundation/Foundation.h>

#import "FBSDKAppEventsState.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings.h"
#import "FBSDKUnarchiverProvider.h"

@interface FBSDKAppEventsStateManager (Internal)
// A quick optimization to allow returning empty array if we know there are no persisted events.
@property (nonatomic, readwrite, assign) BOOL canSkipDiskCheck;
@end

@implementation FBSDKAppEventsStateManager
{
  BOOL _canSkipDiskCheck;
}

- (instancetype)init
{
  self.canSkipDiskCheck = NO;
  return self;
}

- (void)setCanSkipDiskCheck:(BOOL)canSkipDiskCheck
{
  _canSkipDiskCheck = canSkipDiskCheck;
}

- (BOOL)canSkipDiskCheck
{
  return _canSkipDiskCheck;
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
  [[NSFileManager defaultManager] removeItemAtPath:[self filePath]
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

- (NSArray *)retrievePersistedAppEventsStates
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
