/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SUUserManager.h"
#import <FBiOSSDK/FBSessionTokenCachingStrategy.h>
#import <FBiOSSDK/FBGraphPerson.h>

NSString *const SUInvalidSlotNumber = @"com.facebook.SwitchUserSample:InvalidSlotNumber";

static NSString *const SUUserKeyFormat = @"SUUser%d";

@implementation SUUserManager

@synthesize currentSession = _currentSession;
@synthesize currentUserSlot = _currentUserSlot;

- (SUUserManager *)init {
    self = [super init];
    if (self) {
        _currentUserSlot = -1;
    }
    return self;
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
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [[FBSessionTokenCachingStrategy alloc]
                                                           initWithNSUserDefaultAccessTokenKeyName:[NSString stringWithFormat:@"SUUserToken%d", slot]
                                                           expirationDateKeyName:[NSString stringWithFormat:@"SUExpDate%d", slot]];
    return tokenCachingStrategy;
}

- (FBSession*)createSessionForSlot:(int)slot {
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
    
    FBSession *session = [[FBSession alloc] initWithAppID:nil
                                              permissions:nil 
                                          urlSchemeSuffix:nil 
                                       tokenCacheStrategy:tokenCachingStrategy];
    return session;
}

- (id<FBGraphPerson>)getUserInSlot:(int)slot {
    [self validateSlotNumber:slot];

    NSString *key = [NSString stringWithFormat:SUUserKeyFormat, slot];    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [defaults objectForKey:key];
}

- (void)updateUser:(id<FBGraphPerson>)user inSlot:(int)slot {
    [self validateSlotNumber:slot];
    
    NSString *key = [NSString stringWithFormat:SUUserKeyFormat, slot];    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (user != nil ) {
        NSLog(@"SUUserManager updating slot %d: fbid = %@, name = %@", slot, user.id, user.name);
        [defaults setObject:user forKey:key];
    } else {
        NSLog(@"SUUserManager clearing slot %d", slot);

        // Can't be current user anymore
        if (slot == _currentUserSlot) {
            [self switchToNoActiveUser];
        }

        // Also need to tell the token cache to forget the tokens for this user.
        FBSessionTokenCachingStrategy *tokenCachingStrategy = [self createCachingStrategyForSlot:slot];
        [tokenCachingStrategy clearToken:nil];
        
        [defaults removeObjectForKey:key];        
    }
    
    [defaults synchronize];
}

- (void)switchToNoActiveUser {
    NSLog(@"SUUserManager switching to no active user");
    _currentSession = nil;
    _currentUserSlot = -1;
}

- (FBSession *)switchToUserInSlot:(int)slot {
    [self validateSlotNumber:slot];
    NSLog(@"SUUserManager switching to slot %d", slot);
    
    FBSession *session = [self createSessionForSlot:slot];
    
    _currentSession = session;
    _currentUserSlot = slot;
    
    return session;
}

@end
