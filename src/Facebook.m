/*
 * Copyright 2010 Facebook
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

#import "Facebook.h"
#import "FBLoginDialog.h"
#import "FBRequest.h"

static NSString* kDialogBaseURL = @"https://m.facebook.com/dialog/";
static NSString* kGraphBaseURL = @"https://graph.facebook.com/";
static NSString* kRestserverBaseURL = @"https://api.facebook.com/method/";

static NSString* kFBAppAuthURLScheme = @"fbauth";
static NSString* kFBAppAuthURLPath = @"authorize";
static NSString* kRedirectURL = @"fbconnect://success";

static NSString* kLogin = @"oauth";
static NSString* kSDK = @"ios";
static NSString* kSDKVersion = @"2";

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface Facebook ()

// private properties
@property(nonatomic, retain) NSArray* permissions;
@property(nonatomic, copy) NSString* appId;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Facebook

@synthesize accessToken = _accessToken,
         expirationDate = _expirationDate,
        sessionDelegate = _sessionDelegate,
            permissions = _permissions,
        urlSchemeSuffix = _urlSchemeSuffix,
                  appId = _appId;


///////////////////////////////////////////////////////////////////////////////////////////////////
// private


- (id)initWithAppId:(NSString *)appId
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
 *   appended to the base URL scheme used for SSO. For example,
 *   if your facebook ID is "350685531728" and you set urlSchemeSuffix to
 *   "abcd", the Facebook app will expect your application to bind to
 *   the following URL scheme: "fb350685531728abcd".
 *   This is useful if your have multiple iOS applications that
 *   share a single Facebook application id (for example, if you
 *   have a free and a paid version on the same app) and you want
 *   to use SSO with both apps. Giving both apps different
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
- (id)initWithAppId:(NSString *)appId
    urlSchemeSuffix:(NSString *)urlSchemeSuffix
        andDelegate:(id<FBSessionDelegate>)delegate {
  
  self = [super init];
  if (self) {
    self.appId = appId;
    self.sessionDelegate = delegate;
    self.urlSchemeSuffix = urlSchemeSuffix;
  }
  return self;
}

/**
 * Override NSObject : free the space
 */
- (void)dealloc {
  [_accessToken release];
  [_expirationDate release];
  [_request release];
  [_loginDialog release];
  [_fbDialog release];
  [_appId release];
  [_permissions release];
  [_urlSchemeSuffix release];
  [super dealloc];
}

/**
 * A private helper function for sending HTTP requests.
 *
 * @param url
 *            url to send http request
 * @param params
 *            parameters to append to the url
 * @param httpMethod
 *            http method @"GET" or @"POST"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 */
- (FBRequest*)openUrl:(NSString *)url
               params:(NSMutableDictionary *)params
           httpMethod:(NSString *)httpMethod
             delegate:(id<FBRequestDelegate>)delegate {

  [params setValue:@"json" forKey:@"format"];
  [params setValue:kSDK forKey:@"sdk"];
  [params setValue:kSDKVersion forKey:@"sdk_version"];
  if ([self isSessionValid]) {
    [params setValue:self.accessToken forKey:@"access_token"];
  }

  [_request release];
  _request = [[FBRequest getRequestWithParams:params
                                   httpMethod:httpMethod
                                     delegate:delegate
                                   requestURL:url] retain];
  [_request connect];
  return _request;
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
 * A private function for opening the authorization dialog.
 */
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth {
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 _appId, @"client_id",
                                 @"user_agent", @"type",
                                 kRedirectURL, @"redirect_uri",
                                 @"touch", @"display",
                                 kSDK, @"sdk",
                                 nil];

  NSString *loginDialogURL = [kDialogBaseURL stringByAppendingString:kLogin];

  if (_permissions != nil) {
    NSString* scope = [_permissions componentsJoinedByString:@","];
    [params setValue:scope forKey:@"scope"];
  }

  if (_urlSchemeSuffix) {
    [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
  }
  
  // If the device is running a version of iOS that supports multitasking,
  // try to obtain the access token from the Facebook app installed
  // on the device.
  // If the Facebook app isn't installed or it doesn't support
  // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
  // This minimizes the chance that the user will have to enter his or
  // her credentials in order to authorize the application.
  BOOL didOpenOtherApp = NO;
  UIDevice *device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
    if (tryFBAppAuth) {
      NSString *scheme = kFBAppAuthURLScheme;
      if (_urlSchemeSuffix) {
        scheme = [scheme stringByAppendingString:@"2"];
      }
      NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, kFBAppAuthURLPath];
      NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    }

    if (trySafariAuth && !didOpenOtherApp) {
      NSString *nextUrl = [self getOwnBaseUrl];
      [params setValue:nextUrl forKey:@"redirect_uri"];

      NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
    }
  }

  // If single sign-on failed, open an inline login dialog. This will require the user to
  // enter his or her credentials.
  if (!didOpenOtherApp) {
    [_loginDialog release];
    _loginDialog = [[FBLoginDialog alloc] initWithURL:loginDialogURL
                                          loginParams:params
                                             delegate:self];
    [_loginDialog show];
  }
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
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


///////////////////////////////////////////////////////////////////////////////////////////////////
//public

/**
 * Starts a dialog which prompts the user to log in to Facebook and grant
 * the requested permissions to the application.
 *
 * If the device supports multitasking, we use fast app switching to show
 * the dialog in the Facebook app or, if the Facebook app isn't installed,
 * in Safari (this enables single sign-on by allowing multiple apps on
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
  self.permissions = permissions;

  [self authorizeWithFBAppAuth:YES safariAuth:YES];
}

/**
 * This function processes the URL the Facebook application or Safari used to
 * open your application during a single sign-on flow.
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
  // If the URL's structure doesn't match the structure used for Facebook authorization, abort.
  if (![[url absoluteString] hasPrefix:[self getOwnBaseUrl]]) {
    return NO;
  }

  NSString *query = [url fragment];

  // Version 3.2.3 of the Facebook app encodes the parameters in the query but
  // version 3.3 and above encode the parameters in the fragment. To support
  // both versions of the Facebook app, we try to parse the query if
  // the fragment is missing.
  if (!query) {
    query = [url query];
  }

  NSDictionary *params = [self parseURLParams:query];
  NSString *accessToken = [params valueForKey:@"access_token"];

  // If the URL doesn't contain the access token, an error has occurred.
  if (!accessToken) {
    NSString *errorReason = [params valueForKey:@"error"];

    // If the error response indicates that we should try again using Safari, open
    // the authorization dialog in Safari.
    if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
      [self authorizeWithFBAppAuth:NO safariAuth:YES];
      return YES;
    }

    // If the error response indicates that we should try the authorization flow
    // in an inline dialog, do that.
    if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
      [self authorizeWithFBAppAuth:NO safariAuth:NO];
      return YES;
    }

    // The facebook app may return an error_code parameter in case it
    // encounters a UIWebViewDelegate error. This should not be treated
    // as a cancel.
    NSString *errorCode = [params valueForKey:@"error_code"];

    BOOL userDidCancel =
      !errorCode && (!errorReason || [errorReason isEqualToString:@"access_denied"]);
    [self fbDialogNotLogin:userDidCancel];
    return YES;
  }

  // We have an access token, so parse the expiration date.
  NSString *expTime = [params valueForKey:@"expires_in"];
  NSDate *expirationDate = [NSDate distantFuture];
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal != 0) {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    }
  }

  [self fbDialogLogin:accessToken expirationDate:expirationDate];
  return YES;
}

/**
 * Invalidate the current user session by removing the access token in
 * memory and clearing the browser cookie.
 *
 * Note that this method dosen't unauthorize the application --
 * it just removes the access token. To unauthorize the application,
 * the user must remove the app in the app settings page under the privacy
 * settings screen on facebook.com.
 *
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the application has logged out
 */
- (void)logout:(id<FBSessionDelegate>)delegate {

  self.sessionDelegate = delegate;
  [_accessToken release];
  _accessToken = nil;
  [_expirationDate release];
  _expirationDate = nil;

  NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray* facebookCookies = [cookies cookiesForURL:
    [NSURL URLWithString:@"http://login.facebook.com"]];

  for (NSHTTPCookie* cookie in facebookCookies) {
    [cookies deleteCookie:cookie];
  }

  if ([self.sessionDelegate respondsToSelector:@selector(fbDidLogout)]) {
    [_sessionDelegate fbDidLogout];
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
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithParams:(NSMutableDictionary *)params
                    andDelegate:(id <FBRequestDelegate>)delegate {
  if ([params objectForKey:@"method"] == nil) {
    NSLog(@"API Method must be specified");
    return nil;
  }

  NSString * methodName = [params objectForKey:@"method"];
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
 *            “params” you passed in should contain a value of the type
 *            (UIImage *) or (NSData *) which contains the content that you
 *            want to upload
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithMethodName:(NSString *)methodName
                    andParams:(NSMutableDictionary *)params
                andHttpMethod:(NSString *)httpMethod
                  andDelegate:(id <FBRequestDelegate>)delegate {
  NSString * fullURL = [kRestserverBaseURL stringByAppendingString:methodName];
  return [self openUrl:fullURL
                params:params
            httpMethod:httpMethod
              delegate:delegate];
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
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                 andDelegate:(id <FBRequestDelegate>)delegate {

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
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                   andParams:(NSMutableDictionary *)params
                 andDelegate:(id <FBRequestDelegate>)delegate {

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
 *            "POST" and the “params” you passed in should contain a value
 *            of the type (UIImage *) or (NSData *) which contains the
 *            content that you want to upload
 * @param httpMethod
 *            http verb, e.g. "GET", "POST", "DELETE"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                   andParams:(NSMutableDictionary *)params
               andHttpMethod:(NSString *)httpMethod
                 andDelegate:(id <FBRequestDelegate>)delegate {

  NSString * fullURL = [kGraphBaseURL stringByAppendingString:graphPath];
  return [self openUrl:fullURL
                params:params
            httpMethod:httpMethod
              delegate:delegate];
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
  NSMutableDictionary * params = [NSMutableDictionary dictionary];
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
   andDelegate:(id <FBDialogDelegate>)delegate {

  [_fbDialog release];

  NSString *dialogURL = [kDialogBaseURL stringByAppendingString:action];
  [params setObject:@"touch" forKey:@"display"];
  [params setObject:kSDKVersion forKey:@"sdk"];
  [params setObject:kRedirectURL forKey:@"redirect_uri"];

  if (action == kLogin) {
    [params setObject:@"user_agent" forKey:@"type"];
    _fbDialog = [[FBLoginDialog alloc] initWithURL:dialogURL loginParams:params delegate:self];
  } else {
    [params setObject:_appId forKey:@"app_id"];
    if ([self isSessionValid]) {
      [params setValue:[self.accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                forKey:@"access_token"];
    }
    _fbDialog = [[FBDialog alloc] initWithURL:dialogURL params:params delegate:delegate];
  }

  [_fbDialog show];
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
- (void)fbDialogLogin:(NSString *)token expirationDate:(NSDate *)expirationDate {
  self.accessToken = token;
  self.expirationDate = expirationDate;
  if ([self.sessionDelegate respondsToSelector:@selector(fbDidLogin)]) {
    [_sessionDelegate fbDidLogin];
  }

}

/**
 * Did not login call the not login delegate
 */
- (void)fbDialogNotLogin:(BOOL)cancelled {
  if ([self.sessionDelegate respondsToSelector:@selector(fbDidNotLogin:)]) {
    [_sessionDelegate fbDidNotLogin:cancelled];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////

//FBRequestDelegate

/**
 * Handle the auth.ExpireSession api call failure
 */
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error{
  NSLog(@"Failed to expire the session");
}

@end
