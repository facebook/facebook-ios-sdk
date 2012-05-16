/*!
 @header
 @copyright Copyright 2012 Facebook

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 @unsorted
 */

#import <Foundation/Foundation.h>

// up-front decl's
@class FBSession;
@class FBSessionTokenCachingStrategy;

/*! helper macro to test for states that imply a valid session */
#define FB_SESSIONSTATETERMINALBIT (1 << 8)

/*! helper macro to test for states that are terminal */
#define FB_SESSIONSTATEVALIDBIT (1 << 9)

/*
 * Constants defining logging behavior.  Use with [FBSession setLoggingLevel]
 */

/*! Log requests from FBRequest* classes */
#define FB_LOG_BEHAVIOR_FB_REQUESTS @"fb_log_fb_requests"

/*! Log requests from FBURLConnection* classes */
#define FB_LOG_BEHAVIOR_FBURL_CONNECTIONS @"fb_log_fburl_connections"

/*! Include access token in logging. */
#define FB_LOG_BEHAVIOR_INCLUDE_ACCESS_TOKENS @"fb_log_include_access_tokens"

/*! Log session state transitions. */
#define FB_LOG_BEHAVIOR_SESSION_STATE_TRANSITIONS @"fb_log_session_state_transitions"

/*! 
 @typedef FBSessionState enum
 
 @abstract Passed to handler block when a login call has completed
 
 @discussion
 */
typedef enum {
    /*! One of two initial states indicating that no valid cached token was found */
    FBSessionStateCreated               = 0,
    /*! One of two initial session states indicating that a valid cached token was loaded;
     when a session is in this state, a call to login* will result in a valid session,
     without UX or app-switching*/
    FBSessionStateLoadedValidToken      = 1,
    
    /*! Valid session state indicating user is logged in */
    FBSessionStateLoggedIn              = 1 | FB_SESSIONSTATEVALIDBIT,
    /*! Valid session state indicating token has been extended */
    FBSessionStateExtendedToken         = 2 | FB_SESSIONSTATEVALIDBIT,
    
    /*! Invalid session state indicating the user was logged out */
    FBSessionStateLoggedOut             = 1 | FB_SESSIONSTATETERMINALBIT,
    /*! Invalid session state indicating that a login attempt failed */
    FBSessionStateLoginFailed           = 2 | FB_SESSIONSTATETERMINALBIT, // NSError obj w/more info
    /*! Invalid session state indicating that the token was invalidated, but the users session 
        remains cached on the device for later use */
    FBSessionStateInvalidated           = 3 | FB_SESSIONSTATETERMINALBIT, // "
} FBSessionState;

/*! helper macro to test for states that imply a valid session */
#define FB_ISSESSIONVALIDWITHSTATE(state) (0 != (state & FB_SESSIONSTATEVALIDBIT))

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
 @typedef FBSessionStatusHandler block
 
 @abstract Block type used to define blocks callable by FBSession for status updates
 @discussion
 */
typedef void (^FBSessionStatusHandler)(FBSession *session, 
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
 back in the course of processing the single operation (e.g. login)
 
 b) session instances post the "FBSessionLogin" and "FBSessionInvalid"
 notifications, which may be observed via NSNotificationCenter
 
 c) the object supports KVO for property changes
 
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

/*! @abstract indicates whether the session is valid and ready for use with FBRequest, et al. */
@property(readonly) BOOL isValid;                      

/*! @abstract detailed session status */
@property(readonly) FBSessionState status;              

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

 @abstract logs a user on to Facebook

 @description
 Login may be called zero or 1 time, and must be called after init, but before 
 logout or invalidate; calling login at an invalid time results in an exception;
 if a block is passed to login, it is called each time the sessions status 
 changes; the block is released when the session transitions to an invalid state

 @param handler                 a block to call with the login result; default=nil
*/
- (void)loginWithCompletionHandler:(FBSessionStatusHandler)handler;

/*! 
 @method
 
 @abstract logs a user on to Facebook
 
 @description
 Login may be called zero or 1 time, and must be called after init, but before 
 logout or invalidate; calling login at an invalid time results in an exception;
 if a block is passed to login, it is called each time the sessions status 
 changes; the block is released when the session transitions to an invalid state
 
 @param behavior                control whether to allow/force/prohibit SSO (default
                                is FBSessionLoginBehaviorSSOWithFallback)
 @param handler                 a block to call with the login result; default=nil
 */
- (void)loginWithBehavior:(FBSessionLoginBehavior)behavior
        completionHandler:(FBSessionStatusHandler)handler;

/*!
 @abstract
 Invalidates the local session object, and does not clear the persisted cache
 */
- (void)invalidate;

/*!
 @abstract
 Logout invalidates the in-memory session, and clears any persisted cache
*/
- (void)logout;

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

/*!
 @abstract
 Constructor helper to create a session for use in unit tests
 
 @description
 This method creates a session object which creates a test user on login, and destroys the user on
 invalidate; This method should not be used in application code -- but is useful for creating unit tests
 that use the Facebook iOS SDK.
 
 @param permissions     array of strings naming permissions to authorize; nil indicates 
                        a common default set of permissions should be used for unit testing
 */
+ (id)sessionForUnitTestingWithPermissions:(NSArray*)permissions;

@end
