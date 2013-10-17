/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SUUserManager.h"

#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import <FacebookSDK/FacebookSDK.h>

NSString *const SUInvalidSlotNumber = @"com.facebook.SwitchUserSample:InvalidSlotNumber";

static NSString *const SUUserIDKeyFormat = @"SUUserID%d";
static NSString *const SUUserNameKeyFormat = @"SUUserName%d";

@implementation SUUserManager

@synthesize currentSession = _currentSession;
@synthesize currentUserSlot = _currentUserSlot;

- (id)init {
    self = [super init];
    if (self) {
        _currentUserSlot = -1;
    }
    return self;
}

- (void)sendNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SUUserManagerUserChanged"
                                                        object:nil];
}

- (void)validateSlotNumber:(int)slot {
    if (slot < 0 || slot >= [self maximumUserSlots]) {
        [[NSException exceptionWithName:SUInvalidSlotNumber
                                 reason:[NSString stringWithFormat:@"Invalid slot number %d specified", slot]
                               userInfo:nil]
        raise];
    }
}

- (int)maximumUserSlots {
    return 4;
}

- (FBSessionTokenCachingStrategy*)createCachingStrategyForSlot:(int)slot {
    // FBSample logic
    // Token caching strategies are an advanced feature of the SDK; by creating one and passing it to
    // FBSession at instantiation time, the SUUserManager class takes control of the token caching
    // behavior of session instances; this is useful to do in this application, because there may be up
    // to four users whose tokens are remembered by the application at one time; and so the names in
    // NSUserDefaults used to store these values need to reflect the user whose data is being cached
    // Note: an application with more advanced token caching needs (beyond NSUserDefaults) can derive
    // from FBSessionTokenCachingStrategy, and implement any store for the token cache that it needs,
    // including storing and retrieving tokens on an application-specific server, filesystem, etc.
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [[FBSessionTokenCachingStrategy alloc]
                                                           initWithUserDefaultTokenInformationKeyName:[NSString stringWithFormat:@"SUUserTokenInfo%d", slot]];
    return tokenCachingStrategy;
}

- (BOOL)isSlotEmpty:(int)slot {
    return [self getUserIDInSlot:slot] == nil;
}

- (BOOL)areAllSlotsEmpty {
    int numSlots = [self maximumUserSlots];
    for (int i = 0; i < numSlots; ++i) {
        if ([self isSlotEmpty:i] == NO) {
            return NO;
        }
    }
    return YES;
}

- (FBSession*)createSessionForSlot:(int)slot {
    // FBSample logic
    // Getting the right strategy instance for the right slot matters for this application
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];

    // create a session object, with defaults accross the board, except that we provide a custom
    // instance of FBSessionTokenCachingStrategy
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:@[@"basic_info",@"user_birthday"]
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:tokenCachingStrategy];
    return session;
}

- (NSString*)getUserNameInSlot:(int)slot {
    [self validateSlotNumber:slot];

    NSString *key = [NSString stringWithFormat:SUUserNameKeyFormat, slot];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Don't assume we have a full FBGraphObject -- builds compiled with earlier versions of SDK
    // may have saved only a plain NSDictionary.
    return [defaults objectForKey:key];
}

- (NSString*)getUserIDInSlot:(int)slot {
    [self validateSlotNumber:slot];

    NSString *key = [NSString stringWithFormat:SUUserIDKeyFormat, slot];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Don't assume we have a full FBGraphObject -- builds compiled with earlier versions of SDK
    // may have saved only a plain NSDictionary.
    return [defaults objectForKey:key];
}

- (void)updateUser:(NSDictionary<FBGraphUser> *)user inSlot:(int)slot {
    [self validateSlotNumber:slot];

    NSString *idKey = [NSString stringWithFormat:SUUserIDKeyFormat, slot];
    NSString *nameKey = [NSString stringWithFormat:SUUserNameKeyFormat, slot];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (user != nil ) {
        NSLog(@"SUUserManager updating slot %d: fbid = %@, name = %@", slot, user.id, user.name);
        [defaults setObject:user.id forKey:idKey];
        [defaults setObject:user.name forKey:nameKey];
    } else {
        NSLog(@"SUUserManager clearing slot %d", slot);

        // Can't be current user anymore
        if (slot == _currentUserSlot) {
            [self switchToNoActiveUser];
        }

        // FBSample logic
        // Also need to tell the token cache to forget the tokens for this user
        FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
        [tokenCachingStrategy clearToken];

        [defaults removeObjectForKey:idKey];
        [defaults removeObjectForKey:nameKey];
    }

    [defaults synchronize];

    [self sendNotification];
}

- (void)switchToNoActiveUser {
    NSLog(@"SUUserManager switching to no active user");
    _currentSession = nil;
    _currentUserSlot = -1;
    [self sendNotification];
}

- (FBSession *)switchToUserInSlot:(int)slot {
    [self validateSlotNumber:slot];
    NSLog(@"SUUserManager switching to slot %d", slot);

    FBSession *session = [self createSessionForSlot:slot];

    _currentSession = session;
    _currentUserSlot = slot;

    [self sendNotification];

    return session;
}

@end
