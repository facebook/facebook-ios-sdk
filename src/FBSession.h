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
 * Constants defining logging behavior.  Use with <[FBSession setLoggingBehavior]>.
 */

/*! Log requests from FBRequest* classes */
extern NSString *const FBLogBehaviorFBRequests;

/*! Log requests from FBURLConnection* classes */
extern NSString *const FBLogBehaviorFBURLConnections;

/*! Include access token in logging. */
extern NSString *const FBLogBehaviorAccessTokens;

/*! Log session state transitions. */
extern NSString *const FBLogBehaviorSessionStateTransitions;

/*! Log performance characteristics */
extern NSString *const FBLogBehaviorPerformanceCharacteristics;

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
    /*! One of three pre-open session states indicating that an attempt to open the session
     is underway*/
    FBSessionStateCreatedOpening            = 2,
    
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
 
 @abstract Block type used to define blocks called by <FBSession> for state updates
 @discussion
 */
typedef void (^FBSessionStateHandler)(FBSession *session, 
                                       FBSessionState status, 
                                       NSError *error);

/*! 
 @typedef
 
 @abstract Block type used to define blocks called by <[FBSession reauthorizeWithPermissions]>/.
 
 @discussion
 */
typedef void (^FBSessionReauthorizeResultHandler)(FBSession *session, 
                                                  NSError *error);

/*! 
 @class FBSession

 @abstract
 The `FBSession` object is used to authenticate a user and manage the user's session. After
 initializing a `FBSession` object the Facebook App ID and desired permissions are stored. 
 Opening the session will initiate the authentication flow after which a valid user session
 should be available and subsequently cached. Closing the session can optionally clear the
 cache.
 
 If an  <FBRequest> request requires user authorization then an `FBSession` object should be used.

 
 @discussion
 Instances of the `FBSession` class provide notification of state changes in the following ways:
 
 1. Callers of certain `FBSession` methods may provide a block that will be called
 back in the course of state transitions for the session (e.g. login or session closed).
 
 2. The object supports Key-Value Observing (KVO) for property changes.
 */
@interface FBSession : NSObject

/*!
 @methodgroup Creating a session
 */

/*!
 @method

 @abstract 
 Returns a newly initialized Facebook session with default values for the parameters
 to <initWithAppID:permissions:urlSchemeSuffix:tokenCacheStrategy:>.
 */
- (id)init;

/*!
 @method
 
 @abstract
 Returns a newly initialized Facebook session with the specified permissions and other
 default values for parameters to <initWithAppID:permissions:urlSchemeSuffix:tokenCacheStrategy:>.
 
 @param permissions  An array of strings representing the permissions to request during the
 authentication flow. A value of nil will indicates basic permissions. The default is nil.

 */
- (id)initWithPermissions:(NSArray*)permissions;

/*!
 @method
 
 @abstract
 Following are the descriptions of the arguments along with their 
 defaults when ommitted.
 
 @param permissions  An array of strings representing the permissions to request during the
 authentication flow. A value of nil will indicates basic permissions. The default is nil.
 @param appID  The Facebook App ID for the session. If nil is passed in the default App ID will be obtained from a call to <[FBSession defaultAppID]>. The default is nil.
 @param urlSchemeSuffix  The URL Scheme Suffix to be used in scenarious where multiple iOS apps use one Facebook App ID. A value of nil indicates that this information should be pulled from the plist. The default is nil.
 @param tokenCachingStrategy Specifies a key name to use for cached token information in NSUserDefaults, nil
 indicates a default value of @"FBAccessTokenInformationKey".
 */
- (id)initWithAppID:(NSString*)appID
           permissions:(NSArray*)permissions
       urlSchemeSuffix:(NSString*)urlSchemeSuffix
    tokenCacheStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy;

// instance readonly properties         

/*! @abstract Indicates whether the session is open and ready for use. */
@property(readonly) BOOL isOpen;                      

/*! @abstract Detailed session state */
@property(readonly) FBSessionState state;              

/*! @abstract Identifies the Facebook app which the session object represents. */
@property(readonly, copy) NSString *appID;              

/*! @abstract Identifies the URL Scheme Suffix used by the session. This is used when multiple iOS apps share a single Facebook app ID. */
@property(readonly, copy) NSString *urlSchemeSuffix;    

/*! @abstract The access token for the session object. */
@property(readonly, copy) NSString *accessToken;

/*! @abstract The expiration date of the access token for the session object. */
@property(readonly, copy) NSDate *expirationDate;    

/*! @abstract The permissions granted to the access token during the authentication flow. */
@property(readonly, copy) NSArray *permissions;

/*!
 @methodgroup Instance methods
 */

/*! 
 @method

 @abstract Opens a session for the Facebook.

 @discussion
 A session may not be used with <FBRequest> and other classes in the SDK until it is open. If, prior 
 to calling open, the session is in the <FBSessionStateCreatedTokenLoaded> state, then no UX occurs, and 
 the session becomes available for use. If the session is in the <FBSessionStateCreated> state, prior
 to calling open, then a call to open causes login UX to occur, either via the Facebook application
 or via mobile Safari.
 
 Open may be called at most once and must be called after the `FBSession` is initialized. Open must
 be called before the session is closed. Calling an open method at an invalid time will result in
 an exception. The open session methods may be passed a block that will be called back when the session
 state changes. The block will be released when the session is closed.

 @param handler A block to call with the state changes. The default is nil.
*/
- (void)openWithCompletionHandler:(FBSessionStateHandler)handler;

/*! 
 @method
 
 @abstract Logs a user on to Facebook.
 
 @discussion
 A session may not be used with <FBRequest> and other classes in the SDK until it is open. If, prior 
 to calling open, the session is in the <FBSessionStateCreatedTokenLoaded> state, then no UX occurs, and 
 the session becomes available for use. If the session is in the <FBSessionStateCreated> state, prior
 to calling open, then a call to open causes login UX to occur, either via the Facebook application
 or via mobile Safari.
 
 The method may be called at most once and must be called after the `FBSession` is initialized. It must
 be called before the session is closed. Calling the method at an invalid time will result in
 an exception. The open session methods may be passed a block that will be called back when the session
 state changes. The block will be released when the session is closed.
 
 @param behavior Controls whether to allow, force, or prohibit Single Sign On. The default
 is to allow Single Sign On.
 @param handler A block to call with session state changes. The default is nil.
 */
- (void)openWithBehavior:(FBSessionLoginBehavior)behavior
        completionHandler:(FBSessionStateHandler)handler;

/*!
 @abstract
 Closes the local in-memory session object, but does not clear the persisted token cache.
 */
- (void)close;

/*!
 @abstract
 Closes the in-memory session, and clears any persisted cache related to the session.
*/
- (void)closeAndClearTokenInformation;

/*!
 @abstract
 Reauthorizes the session, with additional permissions.
  
 @param permissions An array of strings representing the permissions to request during the
 authentication flow. A value of nil will indicates basic permissions. The default is nil.
 @param behavior Controls whether to allow, force, or prohibit Single Sign On. The default
 is to allow Single Sign On.
 @param handler A block to call with session state changes. The default is nil.
 */
- (void)reauthorizeWithPermissions:(NSArray*)permissions
                          behavior:(FBSessionLoginBehavior)behavior
                 completionHandler:(FBSessionReauthorizeResultHandler)handler;

/*!
 @abstract
 A helper method that is used to provide an implementation for 
 [UIApplicationDelegate application:openURL:sourceApplication:annotation:]. It should be invoked during
 the Single Sign On flow and will update the session information based on the incoming URL.
 
 @param url The URL as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].
*/
- (BOOL)handleOpenURL:(NSURL*)url;

/*!
 @methodgroup Class methods
 */

/*!
 @method
 
 @abstract Retrieve the current Facebook SDK logging behavior.
 
 */
+ (NSSet *)loggingBehavior;

/*!
 @method
 
 @abstract Set the current Facebook SDK logging behavior.  This should consist of strings defined as
  constants with FBLogBehavior*, and can be constructed with [NSSet initWithObjects:].
 
 @param loggingBehavior A set of strings indicating what information should be logged.
 */
+ (void)setLoggingBehavior:(NSSet *)loggingBehavior;

/*!
 @method
 
 @abstract Set the default Facebook App ID to use for sessions. The app ID may be
 overridden on a per session basis.
 
 @param appID The default Facebook App ID to use for <FBSession> methods.
 */
+ (void)setDefaultAppID:(NSString*)appID;

/*!
 @method
 
 @abstract Get the default Facebook App ID to use for sessions. If not explicitly
 set, the default will be read from the application's plist. The app ID may be
 overridden on a per session basis.
 */
+ (NSString*)defaultAppID;

@end
