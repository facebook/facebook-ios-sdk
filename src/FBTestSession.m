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

#define SAFE_TO_USE_FBTESTSESSION

#import "FBTestSession.h"
#import "FBSessionManualTokenCachingStrategy.h"
#import "FBError.h"
#import "FBSession+Protected.h"
#import "FBRequest.h"

static NSString *const FBPLISTAppIDKey = @"FacebookAppID";
static NSString *const FBPLISTAppSecretKey = @"FacebookAppSecret";
static NSString *const FBLoginAuthTestUserURLPath = @"oauth/access_token";
static NSString *const FBLoginAuthTestUserCreatePathFormat = @"%@/accounts/test-users";
static NSString *const FBLoginTestUserClientID = @"client_id";
static NSString *const FBLoginTestUserClientSecret = @"client_secret";
static NSString *const FBLoginTestUserGrantType = @"grant_type";
static NSString *const FBLoginTestUserGrantTypeClientCredentials = @"client_credentials";
static NSString *const FBLoginTestUserAccessToken = @"access_token";
static NSString *const FBLoginTestUserID = @"id";

NSString *const FBErrorLoginFailedReasonUnitTestResponseUnrecognized = @"com.facebook.FBiOSSDK:UnitTestResponseUnrecognized";

#pragma mark Private interface

@interface FBTestSession ()

@property (readwrite, copy) NSString *appAccessToken;
@property (readwrite, copy) NSString *testUserID;

- (id)initWithAppID:(NSString*)appID 
          appSecret:(NSString*)appSecret
        permissions:(NSArray*)permissions 
tokenCachingStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy;

+ (void)deleteUnitTestUser:(NSString*)userID accessToken:(NSString*)accessToken;

@end

#pragma mark -

@implementation FBTestSession

@synthesize appAccessToken = _appAccessToken;
@synthesize testUserID = _testUserID;

#pragma mark Lifecycle

- (id)initWithAppID:(NSString*)appID 
          appSecret:(NSString*)appSecret
        permissions:(NSArray*)permissions 
tokenCachingStrategy:(FBSessionTokenCachingStrategy*)tokenCachingStrategy
{
    if (self = [super initWithAppID:appID
                        permissions:permissions
                    urlSchemeSuffix:nil
                 tokenCacheStrategy:tokenCachingStrategy]) {
        self.appAccessToken = [NSString stringWithFormat:@"%@|%@", appID, appSecret];
    }
    
    return self;
}

- (void)dealloc 
{
    [_appAccessToken release];
    [super dealloc];
}

#pragma mark -
#pragma mark Overrides

- (BOOL)transitionToState:(FBSessionState)state
           andUpdateToken:(NSString*)token
        andExpirationDate:(NSDate*)date
              shouldCache:(BOOL)shouldCache
{
    // in case we need these after the transition
    NSString *userID = self.testUserID;

    BOOL didTransition = [super transitionToState:state
                                   andUpdateToken:token
                                andExpirationDate:date
                                      shouldCache:shouldCache];

    if (didTransition && FB_ISSESSIONSTATETERMINAL(self.state)) {
        [FBTestSession deleteUnitTestUser:userID accessToken:self.appAccessToken]; 
    }
                                  
    return didTransition;
}

// core authorization unit testing (no UX + test user) flow
- (void)authorizeWithBehavior:(FBSessionLoginBehavior)behavior {
    // We ignore behavior, since we aren't going to present UI.
    
    // fetch a test user and token
    // note, this fetch uses a manually constructed app token using the appid|appsecret approach,
    // if there is demand for support for apps for which this will not work, we may consider handling 
    // failure by falling back and fetching an app-token via a request; the current approach reduces 
    // traffic for commin unit testing configuration, which seems like the right tradeoff to start with
    NSString *permissionsString = [self.permissions componentsJoinedByString:@","];
    [FBRequest startWithSession:nil
                      graphPath:[NSString stringWithFormat:FBLoginAuthTestUserCreatePathFormat, self.appID]
                     parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"true", @"installed",
                                 permissionsString, @"permissions",
                                 @"post", @"method",
                                 self.appAccessToken, @"access_token",
                                 nil]
                     HTTPMethod:nil
              completionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         if (error) {
             NSLog(@"Error: [FBSession authorizeUnitTestUser] failed with error: %@", error.description);
         }
         id userToken;
         id userID;
         if ([result isKindOfClass:[NSDictionary class]] &&
             (userToken = [result objectForKey:FBLoginTestUserAccessToken]) &&
             [userToken isKindOfClass:[NSString class]] &&
             (userID = [result objectForKey:FBLoginTestUserID]) &&
             [userID isKindOfClass:[NSString class]]) {
             
             // capture the id for future use
             self.testUserID = userID;
             
             // set token and date, state transition, and call the handler if there is one
             [self transitionAndCallHandlerWithState:FBSessionStateOpen
                                               error:nil
                                               token:userToken
                                      expirationDate:[NSDate distantFuture]
                                         shouldCache:NO];
         } else {
             // we fetched something unexpected when requesting an app token
             NSError *loginError = [FBSession errorLoginFailedWithReason:FBErrorLoginFailedReasonUnitTestResponseUnrecognized
                                                               errorCode:nil];
             // state transition, and call the handler if there is one
             [self transitionAndCallHandlerWithState:FBSessionStateClosedLoginFailed
                                               error:loginError
                                               token:nil
                                      expirationDate:nil
                                         shouldCache:NO];
         }
     }];
}

#pragma mark -
#pragma mark Class methods

+ (id)sessionForUnitTestingWithPermissions:(NSArray*)permissions 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // fetch config contents
    NSString *configFilename = [documentsDirectory stringByAppendingPathComponent:@"FBiOSSDK-UnitTestConfig.plist"];
    NSDictionary *configSettings = [NSDictionary dictionaryWithContentsOfFile:configFilename];
    
    NSString *appID = [configSettings objectForKey:FBPLISTAppIDKey];
    NSString *appSecret = [configSettings objectForKey:FBPLISTAppSecretKey];
    if (!appID || !appSecret) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:
          @"FBSession: Missing AppID or AppSecret; FBiOSSDK-UnitTestConfig.plist is "
          @"is missing or invalid; to create a Facebook AppID, "
          @"visit https://developers.facebook.com/apps"
                               userInfo:nil]
         raise];
    }

    FBSessionManualTokenCachingStrategy *tokenCachingStrategy = 
    [[FBSessionManualTokenCachingStrategy alloc] init];

    if (!permissions.count) {
        permissions = [NSArray arrayWithObjects:@"email", @"publish_actions", nil];
    }

    // call our internal designated initializer to create a unit-testing instance
    FBTestSession *session = [[[FBTestSession alloc] 
                               initWithAppID:appID 
                                   appSecret:appSecret 
                                 permissions:permissions 
                        tokenCachingStrategy:tokenCachingStrategy]
            autorelease];

    [tokenCachingStrategy release];

    return session;
}

+ (void)deleteUnitTestUser:(NSString*)userID accessToken:(NSString*)accessToken {
    if (userID && accessToken) {
        // use FBRequest/FBRequestConnection to create an NSURLRequest
        FBRequest *temp = [[FBRequest alloc ] initWithSession:nil
                                                    graphPath:userID
                                                   parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                               @"delete", @"method",
                                                               accessToken, @"access_token",
                                                               nil]
                                                   HTTPMethod:nil];
        FBRequestConnection *connection = [[FBRequestConnection alloc] init];
        [connection addRequest:temp completionHandler:nil];
        NSURLRequest *request = connection.urlRequest;
        [temp release];
        [connection release];
        
        // synchronously delete the user
        NSURLResponse *response;
        NSError *error = nil;
        NSData *data;
        data = [NSURLConnection sendSynchronousRequest:request 
                                     returningResponse:&response
                                                 error:&error];
        // if !data or if data == false, log
        NSString *body = !data ? nil : [[[NSString alloc] initWithData:data
                                                              encoding:NSUTF8StringEncoding]
                                        autorelease];
        if (!data || [body isEqualToString:@"false"]) {
            NSLog(@"FBSession !delete test user with id:%@ error:%@", userID, error ? error : body);
        }         
    }
}

#pragma mark -

@end
