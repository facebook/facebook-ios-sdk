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

/*! 
 @class
 
 @abstract
 Implementors execute token and expiration-date caching and fetching logic
 for a Facebook integrated application
 
 @discussion
 FBSessionTokenCachingStrategy is designed to be used as a base class. Inheritors should override
 cacheTokenInformation, fetchTokenInformation, and clearToken. This enables any token caching scheme
 to be used by an application, including no token-caching at all. Implementing a custom FBSessionTokenCachingStrategy
 is an advanced technique; most applications will use the default token caching strategy implemented by the SDK.
 @unsorted
 */
@interface FBSessionTokenCachingStrategy : NSObject

/*!
 @abstract Initializes and returns an instance
 */
- (id)init;

/*!
 @abstract 
 Initializes and returns an instance
 
 @param tokenInformationKeyName     Specifies a key name to use for cached token information in NSUserDefaults, nil
 indicates a default value of @"FBAccessTokenInformationKey"
 */
- (id)initWithUserDefaultTokenInformationKeyName:(NSString*)tokenInformationKeyName;

/*!
 @abstract 
 Called by <FBSession> (and overridden by inheritors), in order to cache token information.
 
 @param tokenInformation            Dictionary containing token information to be cached by the method
 */
- (void)cacheTokenInformation:(NSDictionary*)tokenInformation;

/*!
 @abstract 
 Called by <FBSession> (and overridden by inheritors), in order to fetch cached token information
 
 @discussion
 An overriding implementation should only return a token if it
 can also return an expiration date, otherwise return nil
 */
- (NSDictionary*)fetchTokenInformation;

/*!
 @abstract 
 Called by <FBSession> (and overridden by inheritors), in order delete any cached information for a given token
 
 @discussion
 Not all implementations will make use of the token value passedas an argument; however advanced implementations
 may need the token value in order to locate and delete the cache. An overriding implementation must be able to
 tolerate a nil token, as well as a token value for which no cached information exists
 
 @param token           the access token to clear
 */
- (void)clearToken:(NSString*)token;

/*!
 @abstract 
 Helper function called by the SDK as well as apps, in order to fetch the default strategy instance.
 */
+ (FBSessionTokenCachingStrategy*)defaultInstance;

/*!
 @abstract 
 Helper function called by the SDK as well as application code, used to determine whether a given dictionary
 contains the minimum token information usable by the <FBSession>.
 
 @param tokenInformation            Dictionary containing token information to be validated
 */
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

// The key to use with token information dictionaries to determine whether the token was fetched via SSO
extern NSString *const FBTokenInformationIsSSOKey;

// The key to use with token information dictionaries to get the latest known permissions
extern NSString *const FBTokenInformationPermissionsKey;