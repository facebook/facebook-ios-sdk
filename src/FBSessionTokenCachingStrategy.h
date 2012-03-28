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
- (id)initWithNSUserDefaultAccessTokenKeyName:(NSString*)tokenKeyName
                        expirationDateKeyName:(NSString*)dateKeyName;

- (void)cacheToken:(NSString*)token expirationDate:(NSDate*)date;

// an overriding implementation should only return a token if it
// can also return an expiration date, otherwise return nil
- (NSString*)fetchTokenAndExpirationDate:(NSDate**)date;

// an overriding implementation should be able to tolerate a nil or
// already cleared token value
- (void)clearToken:(NSString*)token;

+ (FBSessionTokenCachingStrategy*)defaultInstance;

@end
