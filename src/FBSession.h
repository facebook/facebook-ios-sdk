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

// up-front decl's
@class FBSession;
@class FBSessionTokenCachingStrategy;

// FBSessionStatus enum
//
// Summary:
// Passed to handler block when a login call has completed
typedef enum _FBSessionStatus {
    // initial pre-valid invalid state
    FBSessionStatusInitial              = 0,
    
    // valid session status values
    FBSessionStatusLoggedIn             = 1001,  
    FBSessionStatusTokenExtended        = 1002,  
    FBSessionStatusValidCachedToken     = 1003,
    
    // invalid session status values
    FBSessionStatusLoggedOut            = 1,
    FBSessionStatusLoginFailed          = 2, // NSError obj w/more info
    FBSessionStatusSessionInvalidated   = 3, // "
    
} FBSessionStatus;

typedef void (^FBSessionStatusCallback)(FBSession *session, 
                                        FBSessionStatus status, 
                                        NSError *error);

// FBSession class
//
// Summary:
// FBSession object is used to authenticate/authorize a user, as well
// as to manage the related access token. An FBSession object is required
// for all authenticated uses of FBRequest.
// 
// Behavior notes:
// Instances of the FBSession class notifiy of state changes in these ways; 
// a) callers of certain session* methods may provide a block to be called
// back in the course of processing the single operation (e.g. login)
// b) session instances post the "FBSessionLogin" and "FBSessionInvalid"
// notifications, which may be observed via NSNotificationCenter
// c) the object supports KVO for property changes
@interface FBSession : NSObject

// creating a session

// session/sessionWithPermissions returns a session instance
//
// Summary:
// The simplest factory method requires only an appId to initiate a session with
// Facebook. Following are the descriptions of the arguments along with 
// their defaults when ommitted.
//   permissions:          - array of strings naming permissions to authorize; a 
//                         nil value indicates access to basic information; 
//                         default=nil
//   appId:                - returns a session object for the given app id; nil
//                         specifies that the appId should be pulled from the
//                         plist; default=nil
//   urlSchemeSuffix:      - suffix, used for cases where multiple iOS apps use 
//                         a single appid; nil indicates the urlSchemeSuffix
//                         should be pulled from plist; default=nil
//   tokenCachingStrategy: - policy object for fetching and storing a cached
//                         token value; when nil, the token and expiration date
//                         are stored using NSUserDefaults with the names
//                         "FBAccessTokenKey", and "FBExpirationDateKey";
//                         default=nil
//
// Behavior notes: For a first cut at this, we are removing the public ability
// to force an extension to an access token; instead we will implicitly do this
// when requests are made. 
- (id)init;

- (id)initWithPermissions:(NSArray*)permissions;

- (id)initWithAppID:(NSString*)appID
           permissions:(NSArray*)permissions
       urlSchemeSuffix:(NSString*)urlSchemeSuffix
    tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy;

// instance readonly properties
@property(readonly) BOOL isValid;
@property(readonly) FBSessionStatus status;
@property(nonatomic, readonly) NSString *appID;
@property(nonatomic, readonly) NSString *urlSchemeSuffix;
@property(retain, readonly) NSString *accessToken;
@property(retain, readonly) NSDate *expirationDate;
@property(copy, readonly) NSArray *permissions;

// instance methods

// loginWithCompletionBlock logs a user on to Facebook
//
// Summary:
// Login using Facebook
//   WithCompletionBlock   - a block to call with the login result; default=nil
- (void)loginWithCompletionBlock:(FBSessionStatusCallback)handler;

// invalidate
//
// Summary:
// Invalidates the local session object
- (void)invalidate;

// logout
//
// Summary:
// Logout invalidates the in-memory session, and clears any persisted cache
- (void)logout;

// handleOpenURL
//
// Summary:
// Helper method, used to provide an implementation for 
// [UIApplicationDelegate application:openUrl:*] capable of updating a session
// based on the url
- (BOOL)handleOpenURL:(NSURL*)url;

@end

// FBSessionTokenCachingStrategy
//
// Summary:
// Implementors execute token and expiration-date caching and fetching logic
// for a Facebook integrated application
@interface FBSessionTokenCachingStrategy : NSObject

+ (id)init;
+ (id)initWithNSUserDefaultAccessTokenKeyName:(NSString*)tokenKeyName
                         expirationDateKeyName:(NSString*)dateKeyName;

- (void)cacheToken:(NSString*)token expirationDate:(NSDate*)date;
- (NSString*)fetchTokenAndExpirationDate:(NSDate**)date;
- (void)clearToken:(NSString*)token;

@end
