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

#import "Facebook.h"

#import "FBError.h"
#import "FBFrictionlessRequestSettings.h"
#import "FBLogger.h"
#import "FBLoginDialog.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBSessionManualTokenCachingStrategy.h"
#import "FBSessionUtility.h"
#import "FBSettings.h"
#import "FBUtility.h"

static NSString *kRedirectURL = @"fbconnect://success";

static NSString *kLogin = @"oauth";
static NSString *kApprequests = @"apprequests";
static NSString *kSDKVersion = @"2";

// If the last time we extended the access token was more than 24 hours ago
// we try to refresh the access token again.
static const int kTokenExtendThreshold = 24;

static NSString *requestFinishedKeyPath = @"state";
static void *finishedContext = @"finishedContext";
static void *tokenContext = @"tokenContext";

// the following const strings name properties for which KVO is manually handled
static NSString *const FBaccessTokenPropertyName = @"accessToken";
static NSString *const FBexpirationDatePropertyName = @"expirationDate";

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface Facebook () <FBRequestDelegate>

// private properties
@property (nonatomic, copy) NSString *appId;
// session and tokenCaching object implement login logic and token state in Facebook class
@property (nonatomic, readwrite, retain) FBSession *session;
@property (nonatomic) BOOL hasUpdatedAccessToken;
@property (nonatomic, retain) FBSessionManualTokenCachingStrategy *tokenCaching;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Facebook
{
    id<FBSessionDelegate> _sessionDelegate;
    NSMutableSet *_requests;
    FBSession *_session;
    FBSessionManualTokenCachingStrategy *_tokenCaching;
    FBDialog *_fbDialog;
    NSString *_appId;
    NSString *_urlSchemeSuffix;
    BOOL _isExtendingAccessToken;
    FBRequest *_requestExtendingAccessToken;
    NSDate *_lastAccessTokenUpdate;
    FBFrictionlessRequestSettings *_frictionlessRequestSettings;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (instancetype)initWithAppId:(NSString *)appId
                  andDelegate:(id<FBSessionDelegate>)delegate {
    self = [self initWithAppId:appId urlSchemeSuffix:nil andDelegate:delegate];
    return self;
}

/**
 * Initialize the Facebook object with application ID.
 *
 * @param appId the facebook app id
 * @param urlSchemeSuffix
 *   urlSchemeSuffix is a string of lowercase letters that is
 *   appended to the base URL scheme used for Facebook Login. For example,
 *   if your facebook ID is "350685531728" and you set urlSchemeSuffix to
 *   "abcd", the Facebook app will expect your application to bind to
 *   the following URL scheme: "fb350685531728abcd".
 *   This is useful if your have multiple iOS applications that
 *   share a single Facebook application id (for example, if you
 *   have a free and a paid version on the same app) and you want
 *   to use Facebook Login with both apps. Giving both apps different
 *   urlSchemeSuffix values will allow the Facebook app to disambiguate
 *   their URL schemes and always redirect the user back to the
 *   correct app, even if both the free and the app is installed
 *   on the device.
 *   urlSchemeSuffix is supported on version 3.4.1 and above of the Facebook
 *   app. If the user has an older version of the Facebook app
 *   installed and your app uses urlSchemeSuffix parameter, the SDK will
 *   proceed as if the Facebook app isn't installed on the device
 *   and redirect the user to Safari.
 * @param delegate the FBSessionDelegate
 */
- (instancetype)initWithAppId:(NSString *)appId
              urlSchemeSuffix:(NSString *)urlSchemeSuffix
                  andDelegate:(id<FBSessionDelegate>)delegate {

    self = [super init];
    if (self) {
        _requests = [[NSMutableSet alloc] init];
        _lastAccessTokenUpdate = [[NSDate distantPast] retain];
        _frictionlessRequestSettings = [[FBFrictionlessRequestSettings alloc] init];
        _tokenCaching = [[FBSessionManualTokenCachingStrategy alloc] init];
        self.appId = appId;
        self.sessionDelegate = delegate;
        self.urlSchemeSuffix = urlSchemeSuffix;

        // observe tokenCaching properties so we can forward KVO
        [self.tokenCaching addObserver:self
                            forKeyPath:FBaccessTokenPropertyName
                               options:NSKeyValueObservingOptionPrior
                               context:tokenContext];
        [self.tokenCaching addObserver:self
                            forKeyPath:FBexpirationDatePropertyName
                               options:NSKeyValueObservingOptionPrior
                               context:tokenContext];
    }
    return self;
}

/**
 * Override NSObject : free the space
 */
- (void)dealloc {

    // this is the one case where the delegate is this object
    _requestExtendingAccessToken.delegate = nil;

    [_session release];
    // remove KVOs for tokenCaching
    [_tokenCaching removeObserver:self forKeyPath:FBaccessTokenPropertyName context:tokenContext];
    [_tokenCaching removeObserver:self forKeyPath:FBexpirationDatePropertyName context:tokenContext];
    [_tokenCaching release];

    for (FBRequest *_request in _requests) {
        [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
    }
    [_lastAccessTokenUpdate release];
    [_requests release];
    _fbDialog.delegate = nil;
    [_fbDialog release];
    [_appId release];
    [_urlSchemeSuffix release];
    [_frictionlessRequestSettings release];
    [super dealloc];
}

- (void)invalidateSession {
    [self.session close];
    [self.tokenCaching clearToken];

    [FBUtility deleteFacebookCookies];

    // setting to nil also terminates any active request for whitelist
    [_frictionlessRequestSettings updateRecipientCacheWithRecipients:nil];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)observeFinishedContextValueForKeyPath:(NSString *)keyPath
                                     ofObject:(id)object
                                       change:(NSDictionary *)change {
    FBRequest *_request = (FBRequest *)object;
    FBRequestState requestState = [_request state];
    if (requestState == kFBRequestStateComplete) {
        if ([_request sessionDidExpire]) {
            [self invalidateSession];
            if ([self.sessionDelegate respondsToSelector:@selector(fbSessionInvalidated)]) {
                [self.sessionDelegate fbSessionInvalidated];
            }
        }
        [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
        [_requests removeObject:_request];
    }

}
#pragma GCC diagnostic pop

- (void)observeTokenContextValueForKeyPath:(NSString *)keyPath
                                    change:(NSDictionary *)change {
    // here we are forwarding KVO notifications from an inner object
    if ([change objectForKey:NSKeyValueChangeNotificationIsPriorKey]) {
        [self willChangeValueForKey:keyPath];
    } else {
        [self didChangeValueForKey:keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // dispatch for various observe cases
    if (context == finishedContext) {
        [self observeFinishedContextValueForKeyPath:keyPath
                                           ofObject:object
                                             change:change];
    } else if (context == tokenContext) {
        [self observeTokenContextValueForKeyPath:keyPath
                                          change:change];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

/**
 * A private function for getting the app's base url.
 */
- (NSString *)getOwnBaseUrl {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            _appId,
            _urlSchemeSuffix ? _urlSchemeSuffix : @""];
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary *)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

- (void)updateSessionIfTokenUpdated {
    if (self.hasUpdatedAccessToken) {
        self.hasUpdatedAccessToken = NO;

        // invalidate current session and create a new one with the same permissions
        NSArray *permissions = self.session.accessTokenData.permissions;
        [self.session close];
        self.session = [[[FBSession alloc] initWithAppID:_appId
                                             permissions:permissions
                                         urlSchemeSuffix:_urlSchemeSuffix
                                      tokenCacheStrategy:self.tokenCaching]
                        autorelease];

        // get the session into a valid state
        [self.session openWithCompletionHandler:nil];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
//public

/**
 * Starts a dialog which prompts the user to log in to Facebook and grant
 * the requested permissions to the application.
 *
 * If the device supports multitasking, we use fast app switching to show
 * the dialog in the Facebook app or, if the Facebook app isn't installed,
 * in Safari (this enables Facebook Login by allowing multiple apps on
 * the device to share the same user session).
 * When the user grants or denies the permissions, the app that
 * showed the dialog (the Facebook app or Safari) redirects back to
 * the calling application, passing in the URL the access token
 * and/or any other parameters the Facebook backend includes in
 * the result (such as an error code if an error occurs).
 *
 * See http://developers.facebook.com/docs/authentication/ for more details.
 *
 * Also note that requests may be made to the API without calling
 * authorize() first, in which case only public information is returned.
 *
 * @param permissions
 *            A list of permission required for this application: e.g.
 *            "read_stream", "publish_stream", or "offline_access". see
 *            http://developers.facebook.com/docs/authentication/permissions
 *            This parameter should not be null -- if you do not require any
 *            permissions, then pass in an empty String array.
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the user has logged in.
 */
- (void)authorize:(NSArray *)permissions {

    // if we already have a session, git rid of it
    [self.session close];
    self.session = nil;
    [self.tokenCaching clearToken];

    self.session = [[[FBSession alloc] initWithAppID:_appId
                                         permissions:permissions
                                     urlSchemeSuffix:_urlSchemeSuffix
                                  tokenCacheStrategy:self.tokenCaching]
                    autorelease];

    [self.session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        switch (status) {
            case FBSessionStateOpen:
                // call the legacy session delegate
                [self fbDialogLogin:session.accessTokenData.accessToken expirationDate:session.accessTokenData.expirationDate params:nil];
                break;
            case FBSessionStateClosedLoginFailed:
            { // prefer to keep decls near to their use

                // unpack the error code and reason in order to compute cancel bool
                NSString *errorCode = [[error userInfo] objectForKey:FBErrorLoginFailedOriginalErrorCode];
                NSString *errorReason = [[error userInfo] objectForKey:FBErrorLoginFailedReason];
                BOOL userDidCancel = !errorCode && (!errorReason ||
                                                    [errorReason isEqualToString:FBErrorLoginFailedReasonInlineCancelledValue]);

                // call the legacy session delegate
                [self fbDialogNotLogin:userDidCancel];
            }
                break;
                // presently extension, log-out and invalidation are being implemented in the Facebook class
            default:
                break; // so we do nothing in response to those state transitions
        }
    }];
}

- (NSString *)accessToken {
    return self.tokenCaching.accessToken;
}

- (void)setAccessToken:(NSString *)accessToken {
    self.tokenCaching.accessToken = accessToken;
    self.hasUpdatedAccessToken = YES;
}

- (NSDate *)expirationDate {
    return self.tokenCaching.expirationDate;
}

- (void)setExpirationDate:(NSDate *)expirationDate {
    self.tokenCaching.expirationDate = expirationDate;
    self.hasUpdatedAccessToken = YES;
}

/**
 * Attempt to extend the access token.
 *
 * Access tokens typically expire within 30-60 days. When the user uses the
 * app, the app should periodically try to obtain a new access token. Once an
 * access token has expired, the app can no longer renew it. The app then has
 * to ask the user to re-authorize it to obtain a new access token.
 *
 * To ensure your app always has a fresh access token for active users, it's
 * recommended that you call extendAccessTokenIfNeeded in your application's
 * applicationDidBecomeActive: UIApplicationDelegate method.
 */
- (void)extendAccessToken {
    if (_isExtendingAccessToken) {
        return;
    }
    _isExtendingAccessToken = YES;
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"auth.extendSSOAccessToken", @"method",
                                   nil];
    _requestExtendingAccessToken = [self requestWithParams:params andDelegate:self];
}

/**
 * Calls extendAccessToken if shouldExtendAccessToken returns YES.
 */
- (void)extendAccessTokenIfNeeded {
    if ([self shouldExtendAccessToken]) {
        [self extendAccessToken];
    }
}

/**
 * Returns YES if the last time a new token was obtained was over 24 hours ago.
 */
- (BOOL)shouldExtendAccessToken {
    if ([self isSessionValid]) {
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        NSDateComponents *components = [calendar components:NSHourCalendarUnit
                                                   fromDate:_lastAccessTokenUpdate
                                                     toDate:[NSDate date]
                                                    options:0];

        if (components.hour >= kTokenExtendThreshold) {
            return YES;
        }
    }
    return NO;
}

/**
 * This function processes the URL the Facebook application or Safari used to
 * open your application during a Facebook Login flow.
 *
 * You MUST call this function in your UIApplicationDelegate's handleOpenURL
 * method (see
 * http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html
 * for more info).
 *
 * This will ensure that the authorization process will proceed smoothly once the
 * Facebook application or Safari redirects back to your application.
 *
 * @param URL the URL that was passed to the application delegate's handleOpenURL method.
 *
 * @return YES if the URL starts with 'fb[app_id]://authorize and hence was handled
 *   by SDK, NO otherwise.
 */
- (BOOL)handleOpenURL:(NSURL *)url {
    return [self.session handleOpenURL:url];
}

/**
 * Invalidate the current user session by removing the access token in
 * memory and clearing the browser cookie.
 *
 * Note that this method dosen't unauthorize the application --
 * it just removes the access token. To unauthorize the application,
 * the user must remove the app in the app settings page under the privacy
 * settings screen on facebook.com.
 */
- (void)logout {
    [self invalidateSession];

    if ([self.sessionDelegate respondsToSelector:@selector(fbDidLogout)]) {
        [self.sessionDelegate fbDidLogout];
    }
}

/**
 * Invalidate the current user session by removing the access token in
 * memory and clearing the browser cookie.
 *
 * @deprecated Use of a single session delegate, set at app init, is preferred
 */
- (void)logout:(id<FBSessionDelegate>)delegate {
    [self logout];
    // preserve deprecated callback behavior, but leave cached delegate intact
    // avoid calling twice if the passed and cached delegates are the same
    if (delegate != self.sessionDelegate &&
        [delegate respondsToSelector:@selector(fbDidLogout)]) {
        [delegate fbDidLogout];
    }
}

/**
 * Make a request to Facebook's REST API with the given
 * parameters. One of the parameter keys must be "method" and its value
 * should be a valid REST server API method.
 *
 * See http://developers.facebook.com/docs/reference/rest/
 *
 * @param parameters
 *            Key-value pairs of parameters to the request. Refer to the
 *            documentation: one of the parameters must be "method".
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest *)requestWithParams:(NSMutableDictionary *)params
                     andDelegate:(id<FBRequestDelegate>)delegate {
    if ([params objectForKey:@"method"] == nil) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                        formatString:@"API Method must be specified: %@", params];
        return nil;
    }

    NSString *methodName = [params objectForKey:@"method"];
    [params removeObjectForKey:@"method"];

    return [self requestWithMethodName:methodName
                             andParams:params
                         andHttpMethod:@"GET"
                           andDelegate:delegate];
}

/**
 * Make a request to Facebook's REST API with the given method name and
 * parameters.
 *
 * See http://developers.facebook.com/docs/reference/rest/
 *
 *
 * @param methodName
 *             a valid REST server API method.
 * @param parameters
 *            Key-value pairs of parameters to the request. Refer to the
 *            documentation: one of the parameters must be "method". To upload
 *            a file, you should specify the httpMethod to be "POST" and the
 *            "params" you passed in should contain a value of the type
 *            (UIImage *) or (NSData *) which contains the content that you
 *            want to upload
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest *)requestWithMethodName:(NSString *)methodName
                           andParams:(NSMutableDictionary *)params
                       andHttpMethod:(NSString *)httpMethod
                         andDelegate:(id<FBRequestDelegate>)delegate {
    [self updateSessionIfTokenUpdated];
    [self extendAccessTokenIfNeeded];

    FBRequest *request = [[FBRequest alloc] initWithSession:self.session
                                                 restMethod:methodName
                                                 parameters:params
                                                 HTTPMethod:httpMethod];
    [request setDelegate:delegate];
    [request startWithCompletionHandler:nil];

    return request;
}

/**
 * Make a request to the Facebook Graph API without any parameters.
 *
 * See http://developers.facebook.com/docs/api
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest *)requestWithGraphPath:(NSString *)graphPath
                        andDelegate:(id<FBRequestDelegate>)delegate {

    return [self requestWithGraphPath:graphPath
                            andParams:[NSMutableDictionary dictionary]
                        andHttpMethod:@"GET"
                          andDelegate:delegate];
}

/**
 * Make a request to the Facebook Graph API with the given string
 * parameters using an HTTP GET (default method).
 *
 * See http://developers.facebook.com/docs/api
 *
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param parameters
 *            key-value string parameters, e.g. the path "search" with
 *            parameters "q" : "facebook" would produce a query for the
 *            following graph resource:
 *            https://graph.facebook.com/search?q=facebook
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest *)requestWithGraphPath:(NSString *)graphPath
                          andParams:(NSMutableDictionary *)params
                        andDelegate:(id<FBRequestDelegate>)delegate {

    return [self requestWithGraphPath:graphPath
                            andParams:params
                        andHttpMethod:@"GET"
                          andDelegate:delegate];
}

/**
 * Make a request to the Facebook Graph API with the given
 * HTTP method and string parameters. Note that binary data parameters
 * (e.g. pictures) are not yet supported by this helper function.
 *
 * See http://developers.facebook.com/docs/api
 *
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param parameters
 *            key-value string parameters, e.g. the path "search" with
 *            parameters {"q" : "facebook"} would produce a query for the
 *            following graph resource:
 *            https://graph.facebook.com/search?q=facebook
 *            To upload a file, you should specify the httpMethod to be
 *            "POST" and the "params" you passed in should contain a value
 *            of the type (UIImage *) or (NSData *) which contains the
 *            content that you want to upload
 * @param httpMethod
 *            http verb, e.g. "GET", "POST", "DELETE"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest *)requestWithGraphPath:(NSString *)graphPath
                          andParams:(NSMutableDictionary *)params
                      andHttpMethod:(NSString *)httpMethod
                        andDelegate:(id<FBRequestDelegate>)delegate {
    [self updateSessionIfTokenUpdated];
    [self extendAccessTokenIfNeeded];

    FBRequest *request = [[FBRequest alloc] initWithSession:self.session
                                                  graphPath:graphPath
                                                 parameters:params
                                                 HTTPMethod:httpMethod];
    [request setDelegate:delegate];
    [request startWithCompletionHandler:nil];

    return request;
}

/**
 * Generate a UI dialog for the request action.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
   andDelegate:(id<FBDialogDelegate>)delegate {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self dialog:action andParams:params andDelegate:delegate];
}

/**
 * Generate a UI dialog for the request action with the provided parameters.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param parameters
 *            key-value string parameters
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
     andParams:(NSMutableDictionary *)params
   andDelegate:(id<FBDialogDelegate>)delegate {

    [_fbDialog release];

    NSString *dialogURL = [[FBUtility dialogBaseURL] stringByAppendingString:action];
    [params setObject:@"touch" forKey:@"display"];
    [params setObject:kSDKVersion forKey:@"sdk"];
    [params setObject:kRedirectURL forKey:@"redirect_uri"];

    if ([action isEqualToString:kLogin]) {
        [params setObject:FBLoginUXResponseTypeToken forKey:FBLoginUXResponseType];
        _fbDialog = [[FBLoginDialog alloc] initWithURL:dialogURL loginParams:params delegate:self];
    } else {
        [params setObject:_appId forKey:@"app_id"];
        if ([self isSessionValid]) {
            [params setValue:[self.accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                      forKey:@"access_token"];
            [self extendAccessTokenIfNeeded];
        }

        // by default we show dialogs, frictionless cases may have a hidden view
        BOOL invisible = NO;

        // frictionless handling for application requests
        if ([action isEqualToString:kApprequests]) {
            // if frictionless requests are enabled
            if (self.isFrictionlessRequestsEnabled) {
                //  1. show the "Don't show this again for these friends" checkbox
                //  2. if the developer is sending a targeted request, then skip the loading screen
                [params setValue:@"1" forKey:@"frictionless"];
                //  3. request the frictionless recipient list encoded in the success url
                [params setValue:@"1" forKey:@"get_frictionless_recipients"];
            }

            // set invisible if all recipients are enabled for frictionless requests
            id fbid = [params objectForKey:@"to"];
            if (fbid != nil) {
                // if value parses as a json array expression get the list that way
                id fbids = [FBUtility simpleJSONDecode:fbid];
                if (![fbids isKindOfClass:[NSArray class]]) {
                    // otherwise separate by commas (handles the singleton case too)
                    fbids = [fbid componentsSeparatedByString:@","];
                }
                invisible = [self isFrictionlessEnabledForRecipients:fbids];
            }
        }

        _fbDialog = [[FBDialog alloc] initWithURL:dialogURL
                                           params:params
                                  isViewInvisible:invisible
                             frictionlessSettings:_frictionlessRequestSettings
                                         delegate:delegate];
    }

    [_fbDialog show];
}

- (BOOL)isFrictionlessRequestsEnabled {
    return _frictionlessRequestSettings.enabled;
}

- (void)enableFrictionlessRequests {
    [_frictionlessRequestSettings enableWithFacebook:self];
}

- (void)reloadFrictionlessRecipientCache {
    [_frictionlessRequestSettings reloadRecipientCacheWithFacebook:self];
}

- (BOOL)isFrictionlessEnabledForRecipient:(NSString *)fbid {
    return [_frictionlessRequestSettings isFrictionlessEnabledForRecipient:fbid];
}

- (BOOL)isFrictionlessEnabledForRecipients:(NSArray *)fbids {
    return [_frictionlessRequestSettings isFrictionlessEnabledForRecipients:fbids];
}

/**
 * @return boolean - whether this object has an non-expired session token
 */
- (BOOL)isSessionValid {
    return (self.accessToken != nil && self.expirationDate != nil
            && NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);

}

///////////////////////////////////////////////////////////////////////////////////////////////////
//FBLoginDialogDelegate

/**
 * Set the authToken and expirationDate after login succeed
 */
- (void)fbDialogLogin:(NSString *)token expirationDate:(NSDate *)expirationDate params:(NSDictionary *)params {
    // Note this legacy flow does not use `params`.
    [_lastAccessTokenUpdate release];
    _lastAccessTokenUpdate = [[NSDate date] retain];
    [self reloadFrictionlessRecipientCache];
    if ([self.sessionDelegate respondsToSelector:@selector(fbDidLogin)]) {
        [self.sessionDelegate fbDidLogin];
    }
}

/**
 * Did not login call the not login delegate
 */
- (void)fbDialogNotLogin:(BOOL)cancelled {
    if ([self.sessionDelegate respondsToSelector:@selector(fbDidNotLogin:)]) {
        [self.sessionDelegate fbDidNotLogin:cancelled];
    }
}

#pragma mark - FBRequestDelegate Methods
// These delegate methods are only called for requests that extendAccessToken initiated

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    _isExtendingAccessToken = NO;
    _requestExtendingAccessToken = nil;
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    _isExtendingAccessToken = NO;
    _requestExtendingAccessToken = nil;
    NSString *accessToken = [result objectForKey:@"access_token"];
    NSString *expTime = [result objectForKey:@"expires_at"];

    if (accessToken == nil || expTime == nil) {
        return;
    }

    self.accessToken = accessToken;

    NSTimeInterval timeInterval = [expTime doubleValue];
    NSDate *expirationDate = [NSDate distantFuture];
    if (timeInterval != 0) {
        expirationDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    self.expirationDate = expirationDate;
    [_lastAccessTokenUpdate release];
    _lastAccessTokenUpdate = [[NSDate date] retain];

    [self updateSessionIfTokenUpdated];

    if ([self.sessionDelegate respondsToSelector:@selector(fbDidExtendToken:expiresAt:)]) {
        [self.sessionDelegate fbDidExtendToken:accessToken expiresAt:expirationDate];
    }
}

- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data {
}

- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response {
}

- (void)requestLoading:(FBRequest *)request {
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    // these properties must manually notify for KVO
    if ([key isEqualToString:FBaccessTokenPropertyName] ||
        [key isEqualToString:FBexpirationDatePropertyName]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

@end
