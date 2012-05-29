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

/*! helper macro to test for states that imply a open session */
#define FB_SESSIONSTATETERMINALBIT (1 << 8)

/*! helper macro to test for states that are terminal */
#define FB_SESSIONSTATEOPENBIT (1 << 9)

/*
 * Constants defining logging behavior.  Use with [FBSession setLoggingLevel]
 */

/*! Log requests from FBRequest* classes */
#define FB_LOG_BEHAVIOR_FB_REQUESTS @"fb_requests"

/*! Log requests from FBURLConnection* classes */
#define FB_LOG_BEHAVIOR_FBURL_CONNECTIONS @"fburl_connections"

/*! Include access token in logging. */
#define FB_LOG_BEHAVIOR_INCLUDE_ACCESS_TOKENS @"include_access_tokens"

/*! Log session state transitions. */
#define FB_LOG_BEHAVIOR_SESSION_STATE_TRANSITIONS @"state_transitions"

/*! Log performance characteristics */
#define FB_LOG_BEHAVIOR_PERFORMANCE_CHARACTERISTICS @"perf_characteristics"

/*! 
 @typedef FBSessionState enum
 
 @abstract Passed to handler block each time a session state changes
 
 @discussion
 */
typedef enum {
    /*! One of two initial states indicating that no valid cached token was found */
    FBSessionStateCreated                   = 0,
    /*! One of two initial session states indicating that a cached token was loaded;
     when a session is in this state, a call to open* will result in an open session,
     without UX or app-switching*/
    FBSessionStateCreatedTokenLoaded        = 1,
    
    /*! Open session state indicating user has logged in or a cached token is available */
    FBSessionStateOpen                      = 1 | FB_SESSIONSTATEOPENBIT,
    /*! Open session state indicating token has been extended */
    FBSessionStateOpenTokenExtended         = 2 | FB_SESSIONSTATEOPENBIT,
    
    /*! Closed session state indicating that a login attempt failed */
    FBSessionStateClosedLoginFailed         = 1 | FB_SESSIONSTATETERMINALBIT, // NSError obj w/more info
    /*! Closed session state indicating that the session was closed, but the users token 
        remains cached on the device for later use */
    FBSessionStateClosed                    = 2 | FB_SESSIONSTATETERMINALBIT, // "
} FBSessionState;

/*! helper macro to test for states that imply an open session */
#define FB_ISSESSIONOPENWITHSTATE(state) (0 != (state & FB_SESSIONSTATEOPENBIT))

/*! helper macro to test for states that are terminal */
#define FB_ISSESSIONSTATETERMINAL(state) (0 != (state & FB_SESSIONSTATETERMINALBIT))

/*! 
 @typedef FBSessionLoginBehavior enum
 
 @abstract 
 Passed to login to indicate whether single-sign-on (SSO) should be attempted 
 before falling back to asking the user for credentials.

 @discussion
 */
typedef enum {
    /*! Attempt SSO, ask user for credentials if necessary */
    FBSessionLoginBehaviorSSOWithFallback   = 0,    
    /*! Attempt SSO, login fails if SSO fails */
    FBSessionLoginBehaviorSSOOnly           = 1,
    /*! Do not attempt SSO, ask user for credentials */
    FBSessionLoginBehaviorSuppressSSO       = 2,
} FBSessionLoginBehavior;

/*! 
 @typedef
 
 @abstract Block type used to define blocks callable by FBSession for state updates
 @discussion
 */
typedef void (^FBSessionStateHandler)(FBSession *session, 
                                       FBSessionState status, 
                                       NSError *error);

/*! 
 @class FBSession

 @abstract
 FBSession object is used to authenticate/authorize a user, as well
 as to manage the related access token. An FBSession object is required
 for all authenticated uses of FBRequest.
 
 @discussion
 Instances of the FBSession class notifiy of state changes in these ways:
 
 a) callers of certain session* methods may provide a block to be called
 back in the course of state transitions for the session (e.g. login, session closed, etc.)
 
 b) the object supports KVO for property changes
 
 @unsorted
 */
@interface FBSession : NSObject

/*!
 @methodgroup Creating a session
 */

/*!
 @method
 
 @seealso initWithAppID:permissions:urlSchemeSuffix:tokenCacheStrategy: for parameter details
 */
- (id)init;

/*!
 @method
 
 @seealso initWithAppID:permissions:urlSchemeSuffix:tokenCacheStrategy: for parameter details
 */
- (id)initWithPermissions:(NSArray*)permissions;

/*!
 @method
 
 @abstract
 Following are the descriptions of the arguments along with their 
 defaults when ommitted.
 
 @description
 Note: for a first cut at this, we are removing the public ability
 to force an extension to an access token; instead we will implicitly do this
 when requests are made.
 
 @param permissions          array of strings naming permissions to authorize; a 
                             nil value indicates access to basic information; 
                             default=nil
 @param appId                returns a session object for the given app id; nil
                             specifies that the appId should be pulled from the
                             plist; default=nil
 @param urlSchemeSuffix      suffix, used for cases where multiple iOS apps use 
                             a single appid; nil indicates the urlSchemeSuffix
                             should be pulled from plist; default=nil
 @param tokenCachingStrategy policy object for fetching and storing a cached
                             token value; when nil, the token and expiration date
                             are stored using NSUserDefaults with the names
                             "FBAccessTokenKey", and "FBExpirationDateKey";
                             default=nil
 */
- (id)initWithAppID:(NSString*)appID
           permissions:(NSArray*)permissions
       urlSchemeSuffix:(NSString*)urlSchemeSuffix
    tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy;

// instance readonly properties         

/*! @abstract indicates whether the session is open and ready for use with FBRequest, et al. */
@property(readonly) BOOL isOpen;                      

/*! @abstract detailed session state */
@property(readonly) FBSessionState state;              

/*! @abstract identifies the aplication which the session object represents */
@property(readonly, copy) NSString *appID;              

/*! @abstract identifies the suffix used by the session, used when suites of applications share an appID */
@property(readonly, copy) NSString *urlSchemeSuffix;    

/*! @abstract fetches the access token  */
@property(readonly, copy) NSString *accessToken;

/*! @abstract fetches the expiration date of the access token */
@property(readonly, copy) NSDate *expirationDate;    

/*! @abstract fetches an array representing the permissions granted to the access token */
@property(readonly, copy) NSArray *permissions;

/*!
 @methodgroup Instance methods
 */

/*! 
 @method

 @abstract opens a session for a user on Facebook

 @description
 A session may not be used with FBRequest and other classes in the SDK until it is open. If, prior 
 to calling open, the session is in the FBSessionStateCreatedTokenLoaded state, then no UX occurs, and 
 the session becomes available for use. If the session is in the FBSessionStateCreated state, prior
 to calling open, then a call to open causes login UX to occur, either via the Facebook application
 or via Safari.
 
 Open may be called zero or 1 time, and must be called after init, but before 
 close; calling open at an invalid time results in an exception;
 if a block is passed to open, it is called each time the sessions status 
 changes; the block is released when the session transitions to an closed state

 @param handler                 a block to call with the state changes; default=nil
*/
- (void)openWithCompletionHandler:(FBSessionStateHandler)handler;

/*! 
 @method
 
 @abstract logs a user on to Facebook
 
 @description
 A session may not be used with FBRequest and other classes in the SDK until it is open. If, prior 
 to calling open, the session is in the FBSessionStateCreatedTokenLoaded state, then no UX occurs, and 
 the session becomes available for use. If the session is in the FBSessionStateCreated state, prior
 to calling open, then a call to open causes login UX to occur, either via the Facebook application
 or via Safari.
 
 Open may be called zero or 1 time, and must be called after init, but before 
 close; calling open at an invalid time results in an exception;
 if a block is passed to open, it is called each time the sessions status 
 changes; the block is released when the session transitions to an closed state
 
 @param behavior                control whether to allow/force/prohibit SSO (default
                                is FBSessionLoginBehaviorSSOWithFallback)
 @param handler                 a block to call with state changes; default=nil
 */
- (void)openWithBehavior:(FBSessionLoginBehavior)behavior
        completionHandler:(FBSessionStateHandler)handler;

/*!
 @abstract
 Closes the local in-memory session object, but does not clear the persisted token cache
 */
- (void)close;

/*!
 @abstract
 Closes the in-memory session, and clears any persisted cache related to the session
*/
- (void)closeAndClearTokenInformation;

/*!
 @abstract
 Helper method, used to provide an implementation for 
 [UIApplicationDelegate application:openUrl:*] capable of updating a session
 based on the url
*/
- (BOOL)handleOpenURL:(NSURL*)url;

/*!
 @methodgroup Class methods
 */

/*!
 @method
 
 @abstract retrieve the current FB SDK logging behavior.
 
 */
+ (NSSet *)loggingBehavior;

/*!
 @method
 
 @abstract set the current FB SDK logging behavior.  Should consist of strings defined as constants with FB_LOG_BEHAVIOR_* above,
           and can be constructed with [NSSet initWithObjects:]
 
 */
+ (void)setLoggingBehavior:(NSSet *)loggingBehavior;

@end
