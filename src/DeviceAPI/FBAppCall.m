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

#import "FBAppCall+Internal.h"

#import "FBAccessTokenData+Internal.h"
#import "FBAppBridge.h"
#import "FBAppEvents+Internal.h"
#import "FBAppEvents.h"
#import "FBAppLinkData+Internal.h"
#import "FBDialogsData+Internal.h"
#import "FBError.h"
#import "FBGraphObject.h"
#import "FBInternalSettings.h"
#import "FBLogger.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBSessionUtility.h"
#import "FBSettings+Internal.h"
#import "FBUtility.h"

@interface FBAppCall ()

// Defined as readwrite to only allow this module to set it.
@property (nonatomic, readwrite, copy) NSString *ID;

// NOTE: These properties are redeclared here (in addition to +Internal.h) to
// allow the setters to be called by the SDK.
@property (nonatomic, readwrite, retain) NSError *error;
@property (nonatomic, readwrite, retain) FBDialogsData *dialogData;
@property (nonatomic, readwrite, retain) FBAppLinkData *appLinkData;
@property (nonatomic, readwrite, retain) FBAccessTokenData *accessTokenData;

@end

NSString *const FBLastDeferredAppLink = @"com.facebook.sdk:lastDeferredAppLink%@";
NSString *const FBDeferredAppLinkEvent = @"DEFERRED_APP_LINK";
NSString *const FBAppLinkInboundEvent = @"fb_al_inbound";

@implementation FBAppCall

- (instancetype)init {
    return [self initWithID:nil enforceScheme:YES appID:nil urlSchemeSuffix:nil];
}

- (instancetype)init:(BOOL)enforceScheme {
    return [self initWithID:nil enforceScheme:enforceScheme appID:nil urlSchemeSuffix:nil];
}

// designated initializer
- (instancetype)initWithID:(NSString *)ID enforceScheme:(BOOL)enforceScheme appID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix {
    self = [super init];
    if (self) {
        self.ID = ID ?: [[FBUtility newUUIDString] autorelease];

        if (enforceScheme) {
            // If the url scheme is not registered, then the Facebook app cannot call
            // back, and hence this is an invalid call.
            NSString *defaultUrlScheme = [FBSettings defaultURLSchemeWithAppID:appID urlSchemeSuffix:urlSchemeSuffix];
            if (![FBUtility isRegisteredURLScheme:defaultUrlScheme]) {
                [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                    logEntry:[NSString stringWithFormat:@"Invalid use of FBAppCall, %@ is not registered as a URL Scheme. Did you set '%@' in your plist?", defaultUrlScheme, FBPLISTUrlSchemeSuffixKey]];
                [self release];
                return nil;
            }
        }
    }

    return self;
}

// internal factory for parsing app links from reengagement ads; i.e., version field = 2.
// in general, the parameters should consist of the original url followed by the various components to help construct the instance.
+ (FBAppCall *)appCallFromApplinkArgs_v2:(NSURL *)originalURL
                             applinkArgs:(NSDictionary *)applinkArgs
                           createTimeUTC:(NSString *)createTimeUTC
                 originalQueryParameters:(NSDictionary *)originalQueryParameters {
    FBAppCall *appCall = [[[FBAppCall alloc] init:NO] autorelease];

    NSMutableDictionary *methodArgs = [NSMutableDictionary dictionaryWithDictionary:applinkArgs[@"method_args"]];
    if (createTimeUTC) {
        methodArgs[@"tap_time_utc"] = createTimeUTC;
    }

    NSURL *targetURL = [NSURL URLWithString:methodArgs[@"target_url"]];
    appCall.appLinkData = [[[FBAppLinkData alloc] initWithURL:originalURL
                                                    targetURL:targetURL
                                               originalParams:originalQueryParameters
                                                    arguments:methodArgs]
                           autorelease];
    [appCall logInboundAppLinkEvent];
    return appCall;
}

// internal factory for parsing app links data
+ (FBAppCall *)appCallFromApplinkData:(NSURL *)originalURL
                          applinkData:(NSDictionary *)applinkData
              originalQueryParameters:(NSDictionary *)originalQueryParameters {
    FBAppCall *appCall = [[[FBAppCall alloc] init:NO] autorelease];

    NSURL *targetURL = [NSURL URLWithString:applinkData[@"target_url"]];
    NSString *ref = applinkData[@"ref"];
    NSString *userAgent = applinkData[@"user_agent"];
    NSDictionary *refererData = applinkData[@"referer_data"];
    appCall.appLinkData = [[[FBAppLinkData alloc] initWithURL:originalURL
                                                    targetURL:targetURL
                                                          ref:ref
                                                    userAgent:userAgent
                                                  refererData:refererData
                                               originalParams:originalQueryParameters]
                           autorelease];

    [appCall logInboundAppLinkEvent];
    return appCall;
}


// Public factory method.
+ (FBAppCall *)appCallFromURL:(NSURL *)url {
    NSDictionary *queryParams = [FBUtility queryParamsDictionaryFromFBURL:url];
    NSString *applinkDataString = queryParams[@"al_applink_data"];
    NSString *applinkArgsString = queryParams[@"fb_applink_args"];
    // applink data is preferred over applink args if both are present
    if (applinkDataString) {
        NSDictionary *applinkData = [FBUtility simpleJSONDecode:applinkDataString error:nil];
        if (applinkData) {
            return [FBAppCall appCallFromApplinkData:url
                                         applinkData:applinkData
                             originalQueryParameters:queryParams];

        }
    } else if (applinkArgsString) {
        NSString *createTimeUTC = queryParams[@"fb_click_time_utc"];

        NSDictionary *applinkArgs = [FBUtility simpleJSONDecode:applinkArgsString error:nil];
        int version = [applinkArgs[@"version"] intValue];
        if (version) {
            if ([applinkArgs[@"bridge_args"][@"method"] isEqualToString:@"applink"]) {
                if (version == 2) {
                    return [FBAppCall appCallFromApplinkArgs_v2:url applinkArgs:applinkArgs createTimeUTC:createTimeUTC originalQueryParameters:queryParams];
                }
            }
        }
    }
    // if we get here, we were unable to parse the URL.
    return nil;
}

- (void)logInboundAppLinkEvent {
    FBAppLinkData *applinkData = self.appLinkData;
    NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
    if (applinkData.targetURL) {
        logData[@"targetURL"] = [applinkData.targetURL absoluteString];
    }
    if ([applinkData.targetURL host]) {
        logData[@"targetURLHost"] = [applinkData.targetURL host];
    }
    if (applinkData.refererData) {
        if (applinkData.refererData[@"target_url"]) {
            logData[@"referralTargetURL"] = applinkData.refererData[@"target_url"];
        }
        if (applinkData.refererData[@"url"]) {
            logData[@"referralURL"] = applinkData.refererData[@"url"];
        }
        if (applinkData.refererData[@"app_name"]) {
            logData[@"referralAppName"] = applinkData.refererData[@"app_name"];
        }
    }
    if ([applinkData.originalURL absoluteString]) {
        logData[@"inputURL"] = [applinkData.originalURL absoluteString];
    }
    if ([applinkData.originalURL scheme]) {
        logData[@"inputURLScheme"] = [applinkData.originalURL scheme];
    }

    [FBAppEvents logImplicitEvent:FBAppLinkInboundEvent
                       valueToSum:nil
                       parameters:logData
                          session:nil];
    [logData release];
}

- (void)dealloc
{
    [_ID release];
    [_error release];
    [_dialogData release];
    [_appLinkData release];
    [_accessTokenData release];

    [super dealloc];
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, ID: %@",
                               NSStringFromClass([self class]),
                               self,
                               self.ID];

    if (self.accessTokenData) {
        [result appendFormat:@"\n accesstoken: %@", self.accessTokenData];
    }
    if (self.appLinkData) {
        [result appendFormat:@"\n appLinkData: %@", self.appLinkData];
    }
    if (self.dialogData) {
        [result appendFormat:@"\n dialogData: %@", self.dialogData];
    }

    [result appendString:@"\n>\n"];
    return result;
}

- (BOOL)isEqual:(id)other {
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }

    return [self isEqualToAppCall:other];
}

- (BOOL)isEqualToAppCall:(FBAppCall *)appCall {
    if (self == appCall) {
        return YES;
    }

    if (![self.ID isEqual:appCall.ID]) {
        return NO;
    }

    return YES;
}

- (NSUInteger)hash {
    return [self.ID hash];
}

- (BOOL)isValid {
    BOOL valid = (self.ID != nil);
    if (self.dialogData) {
        valid &= self.dialogData.isValid;
    }
    if (self.appLinkData) {
        valid &= self.appLinkData.isValid;
    }
    return valid;
}

+ (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:nil
                    fallbackHandler:nil];
}

+ (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
      fallbackHandler:(FBAppCallHandler)handler {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:(NSString *)sourceApplication
                        withSession:nil
                    fallbackHandler:handler];
}

+ (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
          withSession:(FBSession *)session {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:(NSString *)sourceApplication
                        withSession:session
                    fallbackHandler:nil];
}

+ (BOOL)handleOpenURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
          withSession:(FBSession *)session
      fallbackHandler:(FBAppCallHandler)handler {
    FBSession *workingSession = session ?: FBSession.activeSessionIfExists;
    [FBAppEvents setSourceApplication:sourceApplication openURL:url];

    // Wrap the fallback handler to intercept login flow for FBSession
    FBAppCallHandler sessionHandler = ^(FBAppCall *call) {
        if ([call.dialogData.method isEqualToString:@"auth3"]) {
            // We are here because whatever FBSession was used to call open() to start the login flow, does not
            // exist anymore. This is most likely caused by the app shutting down prior to the login flow completing.
            // If that FBSession was still around, we would NOT be here.
            // However, we do want to give the fallback handler an opportunity to open a session with the incoming
            // access token if it exists in the url. Additionally, since FBAppCalls for login flow is internal, we
            // will want to create a new FBAppCall that just contains the access token and none of the other internal
            // login data.
            NSDictionary *results = call.dialogData.results;
            NSDate *expirationDate = [FBUtility expirationDateFromExpirationUnixTimeString:results[@"expires"]];
            NSString *userID = [FBSessionUtility userIDFromSignedRequest:results[@"signed_request"]];

            FBAccessTokenData *accessToken = [FBAccessTokenData createTokenFromString:results[@"access_token"]
                                                                          permissions:results[@"permissions"]
                                                                  declinedPermissions:nil
                                                                       expirationDate:expirationDate
                                                                            loginType:FBSessionLoginTypeFacebookApplication
                                                                          refreshDate:nil
                                                               permissionsRefreshDate:nil
                                                                                appID:nil
                                                                               userID:userID];

            // In some cases, it might be fine to go ahead and open the session anyways.
            if ([FBAppCall tryOpenSession:workingSession withAccessToken:accessToken]) {
                return;
            }

            // TODO : Add support for receiving app links via the bridge.
            // In the meantime, any token that did not result in an open session above, will need to be
            // handed back to the fallback handler.
            if ([FBAppCall invokeHandler:handler withAccessToken:accessToken appLinkData:nil]) {
                return;
            }

            // So now we couldn't extract an access token from the results either. However, we know for sure
            // that this is a bridge-login response. So if we have a handler, respond with an error
            NSError *innerError = [FBSession sdkSurfacedErrorForNativeLoginError:call.error];
            [FBAppCall invokeHandler:handler
                           withError:[NSError errorWithDomain:FacebookSDKDomain
                                                         code:FBErrorLoginFailedOrCancelled
                                                     userInfo:innerError ? @{FBInnerErrorObjectKey : innerError} : nil]];
        } else if (handler) {
            // This isn't login flow, so fall back.
            handler(call);
        }
    };

    // Call the bridge first to see if this is a bridge response
    if ([[FBAppBridge sharedInstance] handleOpenURL:url
                                  sourceApplication:sourceApplication
                                            session:session
                                    fallbackHandler:sessionHandler]) {
        return YES;
    }

    // If this is a web login, Add "close" timestamp to e2eMetrics & log the dialog load performance stats
    // ("e2e" is expected to be a NSString - json encoded dictionary, if it's not - there's no sense to log anything)
    NSDictionary *params = [FBUtility queryParamsDictionaryFromFBURL:url];
    NSString *e2eMetrics = [params objectForKey:@"e2e"];
    NSMutableDictionary *e2eMetricsMutableDict = [[[FBUtility simpleJSONDecode:e2eMetrics] mutableCopy] autorelease];
    if ([e2eMetricsMutableDict isKindOfClass:[NSDictionary class]]) {
        e2eMetricsMutableDict[@"close"] = [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])];
        e2eMetrics = [FBUtility simpleJSONEncode:e2eMetricsMutableDict];

        [FBAppEvents logImplicitEvent:FBAppEventNameFBDialogsWebLoginCompleted
                           valueToSum:nil
                           parameters:@{
                                        FBAppEventsWebLoginE2E : e2eMetrics,
                                        @"app_id" : [FBSettings defaultAppID]
                                        }
                              session:nil];
    }

    // If we are here, it wasn't a bridge response and might be a non-native-login url response
    if ([workingSession handleOpenURL:url]) {
        return YES;
    }

    // Last option is to see if maybe this has an access token. If yes, defer to handler to decide how to
    // proceed with the access token.
    FBAccessTokenData *accessToken = [FBAccessTokenData createTokenFromFacebookURL:url
                                                                             appID:[FBSettings defaultAppID]
                                                                   urlSchemeSuffix:[FBSettings defaultUrlSchemeSuffix]];

    if ([FBSessionUtility isOpenSessionResponseURL:url]) {
        // If we're here, it's because the session was not specified or was not expecting a token. In some cases,
        // it might be fine to go ahead and open the session anyways.
        if ([FBAppCall tryOpenSession:workingSession withAccessToken:accessToken]) {
            return YES;
        }
    }

    FBAppLinkData *appLinkData = [FBAppLinkData createFromURL:url];
    if ([FBAppCall invokeHandler:handler withAccessToken:accessToken appLinkData:appLinkData]) {
        return YES;
    }

    // None of the above worked, so bail out.
    return NO;
}

+ (void)handleDidBecomeActive {
    [FBAppCall handleDidBecomeActiveWithSession:nil];
}

+ (void)handleDidBecomeActiveWithSession:(FBSession *)session {
    // If this is a pending native login, the completion handler for the Session will be called
    // and state will be set appropriately. The next call directly into FBSession will end up
    // being a no-op.
    // TODO : Make sure that this happens when native login is supported via FBSession
    [[FBAppBridge sharedInstance] handleDidBecomeActive];

    // If the app was shutdown with a pending login, the old session (and its state) is lost
    // and this next call will end up being a no-op.
    [session handleDidBecomeActive];

    // If there isn't an active session, don't bother creating one to just cancel it.
    // Also, don't call handleDidBecomeActive into the same session twice in a row, since we
    // are keeping track of call order in FBSession now.
    if (session != FBSession.activeSessionIfExists) {
        [FBSession.activeSessionIfExists handleDidBecomeActive];
    }
}

+ (BOOL)tryOpenSession:(FBSession *)session
       withAccessToken:(FBAccessTokenData *)accessToken {
    if (!accessToken) {
        return NO;
    }

    // If a session was not specified at all, then we should be free to create a new active session
    // if we need to. This allows the app developer to write simple apps without understanding the concept
    // of FBSession.
    FBSession *workingSession = session ?: FBSession.activeSession;
    if (workingSession == FBSession.activeSession &&
        (workingSession.state == FBSessionStateClosed || workingSession.state == FBSessionStateClosedLoginFailed)) {
        // If we have a defunct active session, replace it!
        // NOTE: This should happen very, VERY rarely, since we are essentially seeing a login response url
        // for, what the app is telling us is a closed Session.
        FBSession.activeSession = [[[FBSession alloc] init] autorelease];
        workingSession = FBSession.activeSession;
    }

    return [workingSession openFromAccessTokenData:accessToken completionHandler:nil raiseExceptionIfInvalidState:NO];
}

+ (BOOL)invokeHandler:(FBAppCallHandler)handler
      withAccessToken:(FBAccessTokenData *)accessToken
          appLinkData:(FBAppLinkData *)appLinkData {
    if (!accessToken && !appLinkData) {
        return NO;
    }

    if (handler) {
        FBAppCall *loginCall = [[[FBAppCall alloc] init] autorelease];
        loginCall.accessTokenData = accessToken;
        loginCall.appLinkData = appLinkData;
        if (appLinkData) {
            [loginCall logInboundAppLinkEvent];
        }

        handler(loginCall);
    }

    return YES;
}

+ (void)invokeHandler:(FBAppCallHandler)handler
            withError:(NSError *)error {
    if (handler) {
        FBAppCall *errorAppCall = [[[FBAppCall alloc] init] autorelease];
        errorAppCall.error = error;

        handler(errorAppCall);
    }
}

+ (void)openDeferredAppLink:(FBAppLinkFallbackHandler)fallbackHandler {
    NSAssert([NSThread isMainThread], @"FBAppCall openDeferredAppLink: must be invoked from main thread.");

    NSString *appID = [FBSettings defaultAppID];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deferredAppLinkKey = [NSString stringWithFormat:FBLastDeferredAppLink, appID, nil];

    // prevent multiple occurrences from happening.
    if ([defaults objectForKey:deferredAppLinkKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            fallbackHandler(nil);
        });
        return;
    }

    // Deferred app links are only currently used for engagement ads, thus we consider the app to be an advertising one.
    // If this is considered for organic, non-ads scenarios, we'll need to retrieve the FBAppSettings.shouldAccessAdvertisingID
    // before we make this call.
    NSMutableDictionary<FBGraphObject> *deferredAppLinkParameters =
        [FBUtility activityParametersDictionaryForEvent:FBDeferredAppLinkEvent
                                     implicitEventsOnly:NO
                              shouldAccessAdvertisingID:YES];

    FBRequest *deferredAppLinkRequest = [[[FBRequest alloc] initForPostWithSession:nil
                                                                         graphPath:[NSString stringWithFormat:@"%@/activities", appID, nil]
                                                                       graphObject:deferredAppLinkParameters] autorelease];

    [deferredAppLinkRequest startWithCompletionHandler:^(FBRequestConnection *connection,
                                                         id result,
                                                         NSError *error) {
        if (!error) {
            // prevent future network requests.
            [defaults setObject:[NSDate date] forKey:deferredAppLinkKey];
            [defaults synchronize];

            NSString *appLinkString = result[@"applink_url"];
            if (appLinkString) {
                NSURL *applinkURL = [NSURL URLWithString:appLinkString];
                NSString *createTimeUtc = result[@"click_time"];
                if (createTimeUtc) {
                    // append/translate the create_time_utc so it can be later interpreted by FBAppCall construction
                    NSString *modifiedURLString = [[applinkURL absoluteString]
                                                   stringByAppendingFormat:@"%@fb_click_time_utc=%@",
                                                   ([applinkURL query]) ? @"&" : @"?" ,
                                                   createTimeUtc ];
                    applinkURL = [NSURL URLWithString:modifiedURLString];
                }

                if ([[UIApplication sharedApplication] canOpenURL:applinkURL]) {
                    [[UIApplication sharedApplication] openURL:applinkURL];
                    return;
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            fallbackHandler(error);
        });
    }];
}
@end
