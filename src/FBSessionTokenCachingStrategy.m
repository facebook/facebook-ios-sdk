/*
 * Copyright 2012 Facebook
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

#import "FBSessionTokenCachingStrategy.h"

// const strings
static NSString *const FBAccessTokenKeyName = @"FBAccessTokenKey";
static NSString *const FBExpirationDateKeyName = @"FBExpirationDateKey";

@implementation FBSessionTokenCachingStrategy {
    NSString *_accessTokenKeyName;
    NSString *_expirationDateKeyName;
}

#pragma mark Lifecycle

- (id)init {
    return [self initWithNSUserDefaultAccessTokenKeyName:nil
                                   expirationDateKeyName:nil];
}

- (id)initWithNSUserDefaultAccessTokenKeyName:(NSString*)accessTokenKeyName
                        expirationDateKeyName:(NSString*)expirationDateKeyName {
    self = [super init];
    if (self) {
        // get-em
        _accessTokenKeyName = accessTokenKeyName ? accessTokenKeyName : FBAccessTokenKeyName;
        _expirationDateKeyName = expirationDateKeyName ? expirationDateKeyName : FBExpirationDateKeyName;

        // keep-em
        [_accessTokenKeyName retain];
        [_expirationDateKeyName retain];
    }
    return self;    
}

- (void)dealloc {
    // let-em go
    [_accessTokenKeyName release];
    [_expirationDateKeyName release];
    [super dealloc];
}

#pragma mark - 
#pragma mark Public Members

- (void)cacheToken:(NSString*)token expirationDate:(NSDate*)date {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:_accessTokenKeyName];
    [defaults setObject:date forKey:_expirationDateKeyName];
    [defaults synchronize];
}

- (NSString*)fetchTokenAndExpirationDate:(NSDate**)date {
    NSString *accessToken = nil;
    NSDate *expirationDate = nil;
    
    // fetch values from defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    accessToken = [defaults objectForKey:_accessTokenKeyName];
    expirationDate = [defaults objectForKey:_expirationDateKeyName];

    // if we have both return both
    if (accessToken && expirationDate) {
        *date = expirationDate;
    } else {
        accessToken = nil; // else return nil
    }
    return accessToken;
}

- (void)clearToken:(NSString*)token {        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:_accessTokenKeyName];
    [defaults removeObjectForKey:_expirationDateKeyName];    
    [defaults synchronize];
}

+ (FBSessionTokenCachingStrategy*)defaultInstance {
    // static state to assure a single default instance here
    static FBSessionTokenCachingStrategy *sharedDefaultInstance = nil;
    static dispatch_once_t onceToken;

    // assign once to the static, if called
    dispatch_once(&onceToken, ^{
        sharedDefaultInstance = [[FBSessionTokenCachingStrategy alloc] init];
    });
    return sharedDefaultInstance;
}


#pragma mark - 

@end
