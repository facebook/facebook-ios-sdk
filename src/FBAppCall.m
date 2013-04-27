/*
 * Copyright 2010-present Facebook.
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

#import "FBAppCall+Internal.h"
#import "FBAppBridge.h"
#import "FBUtility.h"
#import "FBError.h"
#import "FBSession+Internal.h"
#import "FBAccessTokenData+Internal.h"
#import "FBDialogsData+Internal.h"
#import "FBAppLinkData+Internal.h"
#import "FBInsights.h"
#import "FBInsights+Internal.h"
#import "FBSettings.h"
#import "FBSettings+Internal.h"
#import "FBLogger.h"

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

@implementation FBAppCall

- (id)init {
    NSString *uuidString = [[FBUtility newUUIDString] autorelease];
    
    return [self initWithID:uuidString];
}

- (id)initWithID:(NSString *)ID {
    self = [super init];
    if (self) {
        self.ID = ID;
        // If the url scheme is not registered, then the Facebook app cannot call
        // back, and hence this is an invalid call.
        NSString *defaultUrlScheme = [FBSettings defaultURLScheme];
        if (![FBUtility isRegisteredURLScheme:defaultUrlScheme]) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                                logEntry:[NSString stringWithFormat:@"Invalid use of FBAppCall, %@ is not registered as a URL Scheme", defaultUrlScheme]];
            [self release];
            return nil;
        }
    }
    
    return self;
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

- (NSString*)description {
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

+ (BOOL)handleOpenURL:(NSURL*)url
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
      fallbackHandler:(FBAppCallHandler)handler{
    FBSession *workingSession = session ?: FBSession.activeSessionIfExists;
    
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
            FBAccessTokenData *accessToken = [FBAccessTokenData createTokenFromString:results[@"access_token"]
                                                                          permissions:results[@"permissions"]
                                                                       expirationDate:expirationDate
                                                                            loginType:FBSessionLoginTypeFacebookApplication
                                                                          refreshDate:nil];
            
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
                                    fallbackHandler:sessionHandler]) {
        return YES;
    }
    
    // If this is a web login, log the dialog load performance stats
    NSDictionary *params = [FBUtility queryParamsDictionaryFromFBURL:url];
    NSString *e2eMetrics = [params objectForKey:@"e2e"];
    if (e2eMetrics != nil)  {
        [FBInsights logImplicitEvent:FBInsightsEventNameFBDialogsWebLoginCompleted
                          valueToSum:1.0
                          parameters:@{
                            FBInsightsWebLoginE2E : e2eMetrics,
                            FBInsightsWebLoginSwitchbackTime : [NSNumber numberWithDouble:round(1000 * [[NSDate date] timeIntervalSince1970])],
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
    
    if ([FBSession isOpenSessionResponseURL:url]) {
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

@end
