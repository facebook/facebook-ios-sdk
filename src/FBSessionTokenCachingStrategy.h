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

#import <Foundation/Foundation.h>


// FBSessionTokenCachingStrategy
//
// Summary:
// Implementors execute token and expiration-date caching and fetching logic
// for a Facebook integrated application
//
@interface FBSessionTokenCachingStrategy : NSObject

- (id)init;
- (id)initWithUserDefaultTokenInformationKeyName:(NSString*)tokenInformationKeyName;

- (void)cacheTokenInformation:(NSDictionary*)tokenInformation;

// an overriding implementation should only return a token if it
// can also return an expiration date, otherwise return nil
- (NSDictionary*)fetchTokenInformation;

// an overriding implementation should be able to tolerate a nil or
// already cleared token value
- (void)clearToken:(NSString*)token;

+ (FBSessionTokenCachingStrategy*)defaultInstance;

+ (BOOL)isValidTokenInformation:(NSDictionary*)tokenInformation;

@end

// The key to use with token information dictionaries to get and set the token value
extern NSString *const FBTokenInformationTokenKey;

// The to use with token information dictionaries to get and set the expiration date
extern NSString *const FBTokenInformationExpirationDateKey;

// The to use with token information dictionaries to get and set the refresh date
extern NSString *const FBTokenInformationRefreshDateKey;

// The key to use with token information dictionaries to get the related user's fbid
extern NSString *const FBTokenInformationUserFBIDKey;

