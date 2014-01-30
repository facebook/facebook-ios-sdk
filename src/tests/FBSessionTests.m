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

#import "FBSessionTests.h"
#import "FBTestSession.h"
#import "FBRequest.h"
#import "FBGraphUser.h"
#import "FBTestBlocker.h"
#import "FBTests.h"
#import "FBUtility.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBSessionUtility.h"
#import "FBSystemAccountStoreAdapter.h"
#import "FBAccessTokenData+Internal.h"
#import "FBError.h"
#import "FBUtility.h"
#import "FBSettings.h"
#import <objc/objc-runtime.h>

static NSString *kURLSchemeSuffix = @"URLSuffix";

// We test quite a few deprecated properties.
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBSession (Testing)

@property(readwrite, copy) NSDate *refreshDate;
@property(readwrite) FBSessionLoginType loginType;

- (void)authorizeWithPermissions:(NSArray *)permissions
                        behavior:(FBSessionLoginBehavior)behavior
                 defaultAudience:(FBSessionDefaultAudience)audience
                   isReauthorize:(BOOL)isReauthorize;
- (void)authorizeWithPermissions:(NSArray *)permissions
                 defaultAudience:(FBSessionDefaultAudience)defaultAudience
                  integratedAuth:(BOOL)tryIntegratedAuth
                       FBAppAuth:(BOOL)tryFBAppAuth
                      safariAuth:(BOOL)trySafariAuth
                        fallback:(BOOL)tryFallback
                   isReauthorize:(BOOL)isReauthorize
             canFetchAppSettings:(BOOL)canFetchAppSettings;
- (FBSystemAccountStoreAdapter *)getSystemAccountStoreAdapter;
- (void)callReauthorizeHandlerAndClearState:(NSError *)error;

@end

#pragma mark - Test suite

@implementation FBSessionTests {
    FBTestBlocker *_blocker;
    Method _originalIsRegisteredCheck;
    Method _swizzledIsRegisteredCheck;
}

+ (BOOL)isRegisteredURLSchemeReplacement:(NSString *)url
{
    return YES;
}

- (void)setUp {
    [super setUp];

    // In general, tests use a mock token caching strategy, but some tests verify behavior using the
    // default strategy and we want to ensure it is clean.
    [[FBSessionTokenCachingStrategy defaultInstance] clearToken];

    FBSession.defaultAppID = nil;
    FBSession.defaultUrlSchemeSuffix = nil;
    FBSession.activeSession = nil;

    _blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    
    _originalIsRegisteredCheck = class_getClassMethod([FBUtility class], @selector(isRegisteredURLScheme:));
    _swizzledIsRegisteredCheck = class_getClassMethod([self class], @selector(isRegisteredURLSchemeReplacement:));
    method_exchangeImplementations(_originalIsRegisteredCheck, _swizzledIsRegisteredCheck);

}

- (void)tearDown {
    [super tearDown];

    [_blocker release];
    _blocker = nil;
    
    method_exchangeImplementations(_swizzledIsRegisteredCheck, _originalIsRegisteredCheck);
    _originalIsRegisteredCheck = nil;
    _swizzledIsRegisteredCheck = nil;
}

#pragma mark Init tests

- (void)testInitWithoutDefaultAppIDThrows {
    @try {
        [[FBSession alloc] init];
        STFail(@"should have gotten exception");
    } @catch (NSException *exception) {
    }
}

- (void)testInitWithDefaultAppIDSetsDefaultValues {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];

    assertThat(session.refreshDate, nilValue());
    assertThatInt(session.loginType, equalToInt(FBSessionLoginTypeNone));
    
    [session release];
}

- (void)testInitWithDefaultAppIDSetsAppID {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];
    
    assertThat(session.appID, equalTo(kTestAppId));
    
    [session release];
}

- (void)testInitWithDefaultAppIDSetsState {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];
    
    assertThatBool(session.isOpen, equalToBool(NO));
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
    
    [session release];
}

- (void)testInitWithPermissionsSetsDefaultValues {
    [FBSession setDefaultAppID:kTestAppId];
    
    NSArray *permissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    FBSession *session = [[FBSession alloc] initWithPermissions:permissions];
    
    assertThat(session.refreshDate, nilValue());
    assertThatInt(session.loginType, equalToInt(FBSessionLoginTypeNone));
    
    [session release];
}

- (void)testInitWithPermissionsSetsPermissions {
    [FBSession setDefaultAppID:kTestAppId];
    
    NSArray *permissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    FBSession *session = [[FBSession alloc] initWithPermissions:permissions];
    
    assertThat(session.permissions, equalTo(permissions));
    
    [session release];
}

- (void)testInitWithoutUrlSchemeSuffixUsesDefault {
    FBSession.defaultUrlSchemeSuffix = @"defaultsuffix";
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    
    assertThat(session.urlSchemeSuffix, equalTo(@"defaultsuffix"));
    
    [session release];
}

- (void)testInitWithUrlSchemeSuffixOverridesDefault {
    FBSession.defaultUrlSchemeSuffix = @"defaultsuffix";
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:@"asuffix"
                                       tokenCacheStrategy:nil];
    
    assertThat(session.urlSchemeSuffix, equalTo(@"asuffix"));
    
    [session release];
}

- (void)testInitWithExpiredTokenClearsTokenCache {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithExpiredToken];
    
    [[(id)mockStrategy expect] clearToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                        tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    [session release];
}

- (void)testInitWithExpiredTokenSetsState {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithExpiredToken];
    
    [[(id)mockStrategy expect] clearToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThatBool(session.isOpen, equalToBool(NO));
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
    
    [session release];
}

- (void)testInitWithValidTokenTransitionsToLoadedState {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithValidToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThatInt(session.state, equalToInt(FBSessionStateCreatedTokenLoaded));
    [session release];
}

- (void)testInitWithValidTokenSetsDefaultValues {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithValidToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThatInt([session.refreshDate timeIntervalSinceNow], closeTo(0, 5000));
    assertThatInt(session.loginType, equalToInt(FBSessionLoginTypeNone));
    
    [session release];
}

- (void)testInitWithValidTokenSetsState {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithValidToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThatBool(session.isOpen, equalToBool(NO));
    assertThatInt(session.state, equalToInt(FBSessionStateCreatedTokenLoaded));
    
    [session release];
}

- (void)testInitWithValidTokenSetsAppID {
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithValidToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.appID, equalTo(kTestAppId));
    
    [session release];
}

- (void)testInitWithValidTokenSetsToken {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.accessToken, equalTo(mockToken.accessToken));
    
    [session release];
}

- (void)testInitWithValidTokenSetsRefreshDate {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    NSDate *refreshDate = [NSDate dateWithTimeIntervalSinceNow:1200];
    [[[(id)mockToken stub] andReturn:refreshDate] refreshDate];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.refreshDate, equalTo(refreshDate));
    
    [session release];
}

- (void)testInitWithValidTokenSetsLoginType {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionLoginType loginType = FBSessionLoginTypeWebView;
    [[[(id)mockToken stub] andReturnValue:OCMOCK_VALUE(loginType)] loginType];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThatInt(session.loginType, equalToInt(FBSessionLoginTypeWebView));
    
    [session release];
}

- (void)testInitWithValidTokenSetsExpirationDate {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];

    assertThat(session.expirationDate, equalTo(mockToken.expirationDate));
    
    [session release];
}

- (void)testInitWithValidTokenSetsPermissions {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)mockToken stub] andReturn:tokenPermissions] permissions];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.permissions, equalTo(tokenPermissions));
    
    [session release];
}

- (void)testInitWithValidTokenAndSubsetOfCachedPermissionsSetsPermissions {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)mockToken stub] andReturn:tokenPermissions] permissions];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    NSArray *sessionPermissions = [NSArray arrayWithObject:@"permission1"];
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:sessionPermissions
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.permissions, equalTo(tokenPermissions));
    
    [session release];
}

- (void)testInitWithValidTokenAndNonSubsetOfCachedPermissionsDoesNotUseCachedToken {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)mockToken stub] andReturn:tokenPermissions] permissions];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    [[(id)mockStrategy expect] clearToken];

    NSArray *sessionPermissions = [NSArray arrayWithObject:@"permission3"];
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:sessionPermissions
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [(id)mockStrategy verify];
    
    assertThat(session.permissions, equalTo(sessionPermissions));
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
    [session release];
}

#pragma mark Opening tests

// These tests test authentication mechanism-agnostic open logic; tests of specific authentication
// mechanisms are found in subclasses of FBAuthenticationTests.

- (void)testOpenTransitionsToOpening {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];
    [mockSession initWithAppID:kTestAppId
                   permissions:nil
               defaultAudience:FBSessionDefaultAudienceNone
               urlSchemeSuffix:nil
            tokenCacheStrategy:nil];

    __block BOOL handlerCalled = NO;
    [mockSession openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        handlerCalled = YES;
    }];
    
    assertThatInt(mockSession.state, equalToInt(FBSessionStateCreatedOpening));
    assertThatBool(handlerCalled, equalToBool(NO));
}

- (void)testOpenWithValidToken {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    __block BOOL handlerCalled = NO;
    [session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        handlerCalled = YES;
    }];
    
    assertThatInt(session.state, equalToInt(FBSessionStateOpen));
    assertThatBool(handlerCalled, equalToBool(YES));
    
    [session release];
}

- (void)testOpenWithValidTokenWithNoHandler {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];

    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [session openWithCompletionHandler:nil];

    assertThatInt(session.state, equalToInt(FBSessionStateOpen));

    [session release];
}

- (void)testOpenThrowsExceptionIfNotInCreated {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [session openWithCompletionHandler:nil];
    
    assertThatInt(session.state, equalToInt(FBSessionStateOpen));
    
    @try {
        [session openWithCompletionHandler:nil];
        STFail(@"should have gotten an exception");
    } @catch (NSException *exception) {
    }
    
    [session release];
    
}

#pragma mark Closing tests

- (void)testCloseWhenCreatedStaysInCreated {
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];

    [session close];
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
}

- (void)testClose {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];

    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [session close];
    // Verify that closing a token loaded session is not valid, it's the same
    // as closing a freshly init'd session (i.e., we also do not support going from
    // FBSessionStateCreated to FBSessionStateClosed).
    assertThatInt(session.state, equalToInt(FBSessionStateCreatedTokenLoaded));
}

- (void)testCloseWhenOpeningSetsClosedLoginFailedState {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];

    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    [session openWithCompletionHandler:nil];
    
    [session close];
    assertThatInt(session.state, equalToInt(FBSessionStateClosedLoginFailed));
}

- (void)testCloseAndClearTokenInformation {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    [[(id)mockStrategy expect] clearToken];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    [session closeAndClearTokenInformation];
    
    [(id)mockStrategy verify];
    
    // Verify that closing a token loaded session is not valid, it's the same
    // as closing a freshly init'd session (i.e., we also do not support going from
    // FBSessionStateCreated to FBSessionStateClosed).
    assertThatInt(session.state, equalToInt(FBSessionStateCreatedTokenLoaded));
}


- (void)testCloseDoesNotSendDidBecomeClosedNotificationIfOpenSessionNotActiveSession {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [self createAndOpenSessionWithMockToken];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidBecomeClosedActiveSessionNotification
                                                   object:nil];
    
    @try {
        [session close];
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testCloseDoesNotSendDidBecomeClosedNotificationIfActiveSessionNotOpen {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];
    FBSession.activeSession = session;

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidBecomeClosedActiveSessionNotification
                                                   object:nil];
    @try {
        [session close];
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testCloseSendsDidBecomeClosedNotificationIfActiveSessionOpen {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [self createAndOpenSessionWithMockToken];
    FBSession.activeSession = session;

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidBecomeClosedActiveSessionNotification
                                                   object:nil];
    [[observerMock expect] notificationWithName:FBSessionDidBecomeClosedActiveSessionNotification
                                         object:[OCMArg any]];
        
    @try {
        [session close];
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

// TODO test from Opening -> close

#pragma mark Reauthorization tests

- (void)testReauthorizeWithReadIsSynonymForRequestNewRead {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];
    
    FBSessionReauthorizeResultHandler handler =^(FBSession *session, NSError *error) {
    };
    
    NSArray *newPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];

    [[(id)mockSession expect] requestNewReadPermissions:newPermissions completionHandler:handler];

    [mockSession reauthorizeWithReadPermissions:newPermissions completionHandler:handler];
    
    [(id)mockSession verify];
}

- (void)testReauthorizeWithPublishIsSynonymForRequestNewPublish {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];
    
    FBSessionReauthorizeResultHandler handler =^(FBSession *session, NSError *error) {
    };
    
    NSArray *newPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    
    [[(id)mockSession expect] requestNewPublishPermissions:newPermissions
                                           defaultAudience:FBSessionDefaultAudienceOnlyMe
                                         completionHandler:handler];
    
    [mockSession reauthorizeWithPublishPermissions:newPermissions
                                   defaultAudience:FBSessionDefaultAudienceOnlyMe
                                 completionHandler:handler];
    
    [(id)mockSession verify];
}

- (void)testReauthorizeFailsIfSessionNotOpen {
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    
    assertThatBool(session.isOpen, equalToBool(NO));
    
    @try {
        [session reauthorizeWithPermissions:nil
                                   behavior:FBSessionLoginBehaviorWithFallbackToWebView
                          completionHandler:nil];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
}

- (void)testReauthorizeWhileReauthorizeInProgressFails {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];
    
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:mockStrategy];
    
    [session openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:nil];
    assertThatBool(session.isOpen, equalToBool(YES));
    
    FBSessionRequestPermissionResultHandler handler = ^(FBSession *session, NSError *error) {
    };
    
    // Because our session is mocked to do nothing with auth requests, it will stay in a "pending"
    // reauth state after this call.
    [session requestNewReadPermissions:nil completionHandler:handler];
    
    @try {
        [session requestNewReadPermissions:nil completionHandler:handler];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
}

- (void)testReauthorizeWithPermissionCallsAuthorizeAgain {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuthThatExpectsCall:YES
                                                                   reauthorize:YES
                                                                      behavior:FBSessionLoginBehaviorWithFallbackToWebView
                                                               defaultAudience:FBSessionDefaultAudienceNone];
    
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];

    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:mockStrategy];

    [session openWithCompletionHandler:nil];
    
    assertThatBool(session.isOpen, equalToBool(YES));
    
    [session reauthorizeWithPermissions:nil
                               behavior:FBSessionLoginBehaviorWithFallbackToWebView
                      completionHandler:nil];
    
    [(id)mockSession verify];
}

- (void)testReauthorizeWhileReauthorizeInProgressFailsWithNilHandler {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];

    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:mockStrategy];
    
    [session openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:nil];
    assertThatBool(session.isOpen, equalToBool(YES));
    
    // Because our session is mocked to do nothing with auth requests, it will stay in a "pending"
    // reauth state after this call.
    [session requestNewReadPermissions:nil completionHandler:^(FBSession *session, NSError *error) {
    }];
    
    BOOL caughtException = NO;
    @try {
        [session requestNewReadPermissions:nil completionHandler:nil];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
        caughtException = YES;
    }
    STAssertTrue(caughtException, @"expected exception when requesting more permissions.");
}

- (void)testRequestNewReadPermissionsFailsIfPassedPublishPermissions {
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    @try {
        [session requestNewReadPermissions:requestedPermissions completionHandler:nil];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
}

- (void)testRequestNewReadPermissionsCallsAuthorizeAgainOnSuccess {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuthThatExpectsCall:YES
                                                                   reauthorize:YES
                                                                      behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                                                               defaultAudience:FBSessionDefaultAudienceNone];
    
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:mockStrategy];
    
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:nil];
    
    assertThatBool(session.isOpen, equalToBool(YES));
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];

    [session requestNewReadPermissions:requestedPermissions
                     completionHandler:nil];
    
    [(id)mockSession verify];
}

- (void)testRequestNewPublishPermissionsCallsAuthorizeAgainOnSuccess {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuthThatExpectsCall:YES
                                                                   reauthorize:YES
                                                                      behavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                                                                       defaultAudience:FBSessionDefaultAudienceOnlyMe];
    
    FBAccessTokenData *mockToken = [self createValidMockToken];
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];
    
    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:mockStrategy];
    
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:nil];
    
    assertThatBool(session.isOpen, equalToBool(YES));
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"publish_permission1", nil];
    
    [session requestNewPublishPermissions:requestedPermissions
                          defaultAudience:FBSessionDefaultAudienceOnlyMe
                       completionHandler:nil];
    
    [(id)mockSession verify];
}

#pragma mark Other instance tests


- (void)testHandleDidBecomeActiveDoesNothingInCreatedState {
    FBSession *mockSession = [self allocMockSessionWithNoOpAuth];
    FBSession *session = [mockSession initWithAppID:kTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [[(id)mockSession reject] close];
    [[(id)mockSession reject] callReauthorizeHandlerAndClearState:[OCMArg any]];
    
    [FBSettings setDefaultAppID:kTestAppId];
    
    [session handleDidBecomeActive];
    
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
}

// TODO when running from the command line, this hangs
/*
- (void)testGetSystemAccountStoreAdapter {
    [FBSession setDefaultAppID:kAppId];
    FBSession *session = [[FBSession alloc] init];
    
    // Only do this if it's available (iOS 6.0+)
    if ([self isSystemVersionAtLeast:@"6.0"]) {
        FBSystemAccountStoreAdapter *adapter = [session getSystemAccountStoreAdapter];
        
        assertThat(adapter, equalTo([FBSystemAccountStoreAdapter sharedInstance]));
    }
    
    [session release];
}

 - (void)testIsSystemAccountStoreAvailable {
 BOOL shouldBeAvailable = [self isSystemVersionAtLeast:@"6.0"];
 
 [FBSession setDefaultAppID:kAppId];
 FBSession *session = [[FBSession alloc] init];
 
 assertThatBool([session isSystemAccountStoreAvailable], equalToBool(shouldBeAvailable));
 }
 
*/

- (void)testIsMultitaskingSupported {
    UIDevice *device = [UIDevice currentDevice];
    BOOL shouldBeSupported = [device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported];

    assertThatBool([FBUtility isMultitaskingSupported], equalToBool(shouldBeSupported));
}

- (void)testWillAttemptToExtendToken {
    FBAccessTokenData *token = [FBAccessTokenData createTokenFromString:@"token"
                                                            permissions:nil
                                                         expirationDate:[NSDate distantFuture]
                                                              loginType:FBSessionLoginTypeFacebookApplication
                                                            refreshDate:[NSDate dateWithTimeIntervalSince1970:0]];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:token];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    [session openWithCompletionHandler:nil];
    
    BOOL shouldExtend = [session shouldExtendAccessToken];
    
    assertThatBool(shouldExtend, equalToBool(YES));
}


#pragma mark Active session tests

- (void)testActiveSessionDefaultsToNewCreatedSession {
    [FBSession setDefaultAppID:kTestAppId];
    
    assertThat(FBSession.activeSessionIfOpen, nilValue());
    FBSession *session = FBSession.activeSession;
    assertThat(session, notNilValue());
    assertThatInt(session.state, equalToInt(FBSessionStateCreated));
}

- (void)testSetActiveSession {
    [FBSession setDefaultAppID:kTestAppId];

    assertThat(FBSession.activeSessionIfOpen, nilValue());

    FBSession *originalActiveSession = FBSession.activeSession;
    assertThat(originalActiveSession, notNilValue());
    
    FBSession *newSession = [[FBSession alloc] init];
    FBSession.activeSession = newSession;
    
    FBSession *activeSession = [FBSession activeSession];
    assertThat(activeSession, notNilValue());
    assertThat(activeSession, equalTo(newSession));
}

- (void)testSetActiveSessionSendsSetNotification {
    [FBSession setDefaultAppID:kTestAppId];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidSetActiveSessionNotification
                                                   object:nil];
    [[observerMock expect] notificationWithName:FBSessionDidSetActiveSessionNotification
                                         object:[OCMArg any]];

    @try {
        FBSession *session = [[FBSession alloc] init];
        FBSession.activeSession = session;
       
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testSetActiveSessionSendsUnsetNotification {
    [FBSession setDefaultAppID:kTestAppId];

    FBSession *existingActiveSession = [[FBSession alloc] init];
    FBSession.activeSession = existingActiveSession;
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidUnsetActiveSessionNotification
                                                   object:nil];
    [[observerMock expect] notificationWithName:FBSessionDidUnsetActiveSessionNotification
                                         object:[OCMArg any]];
    
    @try {
        FBSession *session = [[FBSession alloc] init];
        FBSession.activeSession = session;
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testSetActiveSessionDoesNotSendUnsetNotificationIfNoPreviousSession {
    [FBSession setDefaultAppID:kTestAppId];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidUnsetActiveSessionNotification
                                                   object:nil];
    
    @try {
        FBSession *session = [[FBSession alloc] init];
        FBSession.activeSession = session;
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testSetActiveSessionDoesNotSendDidBecomeOpenNotificationIfSessionNotOpen {
    [FBSession setDefaultAppID:kTestAppId];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidBecomeOpenActiveSessionNotification
                                                   object:nil];
    
    @try {
        FBSession *session = [[FBSession alloc] init];
        FBSession.activeSession = session;
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testSetActiveSessionSendsDidBecomeOpenNotificationIfSessionOpen {
    [FBSession setDefaultAppID:kTestAppId];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock
                                                     name:FBSessionDidBecomeOpenActiveSessionNotification
                                                   object:nil];
    [[observerMock expect] notificationWithName:FBSessionDidBecomeOpenActiveSessionNotification
                                         object:[OCMArg any]];
    
    @try {
        FBSession *session = [self createAndOpenSessionWithMockToken];
        FBSession.activeSession = session;
        
        [observerMock verify];
        
        [session release];
    } @finally {
        // Important to remove this observer no matter what, or other tests will fail if this one does.
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }
}

- (void)testOpenActiveSessionRequiresDefaultAppId {
    @try {
        [FBSession openActiveSessionWithAllowLoginUI:NO];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
}

- (void)testOpenActiveSessionWithNoTokenOrUIStaysInCreated {
    [FBSession setDefaultAppID:kTestAppId];

    BOOL result = [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(NO));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateCreated));
}

- (void)testOpenActiveSessionWithValidTokenAndNoUISucceeds {
    [FBSession setDefaultAppID:kTestAppId];

    FBAccessTokenData *token = [self createValidMockToken];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];

    BOOL result = [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(YES));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateOpen));
    assertThat(activeSession.accessTokenData, equalTo(token));
}

- (void)testOpenActiveSessionWithPermissionsAndValidTokenSucceeds {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];

    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    __block BOOL handlerCalled = NO;
    BOOL result = [FBSession openActiveSessionWithPermissions:requestedPermissions
                                                 allowLoginUI:NO
                                            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                handlerCalled = YES;
                                            }];
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(YES));
    assertThatBool(handlerCalled, equalToBool(YES));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateOpen));
    assertThat(activeSession.accessTokenData, equalTo(token));
    
}

- (void)testOpenActiveSessionRequestingMorePermissionsThanTokenFails {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    __block BOOL handlerCalled = NO;
    BOOL result = [FBSession openActiveSessionWithPermissions:requestedPermissions
                                                 allowLoginUI:NO
                                            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                handlerCalled = YES;
                                            }];
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(NO));
    assertThatBool(handlerCalled, equalToBool(NO));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateCreated));
    
}

- (void)testOpenActiveSessionWithReadPermissionSucceeds {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    __block BOOL handlerCalled = NO;
    
    BOOL result = [FBSession openActiveSessionWithReadPermissions:requestedPermissions
                                                     allowLoginUI:NO
                                                completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                    handlerCalled = YES;
                                                }];
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(YES));
    assertThatBool(handlerCalled, equalToBool(YES));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateOpen));
    assertThat(activeSession.accessTokenData, equalTo(token));
}

- (void)testOpenActiveSessionWithReadRequestingReadAndWritePermissionFails {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    __block BOOL handlerCalled = NO;
    
    @try {
        [FBSession openActiveSessionWithReadPermissions:requestedPermissions
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          handlerCalled = YES;
                                      }];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(handlerCalled, equalToBool(NO));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateCreatedTokenLoaded));
    
}

- (void)testOpenActiveSessionWithPublishRequestingReadAndWritePermissionSucceeds {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    __block BOOL handlerCalled = NO;
    
    BOOL result = [FBSession openActiveSessionWithPublishPermissions:requestedPermissions
                                                     defaultAudience:FBSessionDefaultAudienceOnlyMe
                                                        allowLoginUI:NO
                                                   completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                       handlerCalled = YES;
                                                   }];

    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(result, equalToBool(YES));
    assertThatBool(handlerCalled, equalToBool(YES));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateOpen));
    assertThat(activeSession.accessTokenData, equalTo(token));
}

- (void)testOpenActiveSessionWithPublishAndNoDefaultAudienceFails {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"publish_permission1", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"publish_permission1", nil];
    __block BOOL handlerCalled = NO;
    
    @try {
        [FBSession openActiveSessionWithPublishPermissions:requestedPermissions
                                           defaultAudience:FBSessionDefaultAudienceNone
                                              allowLoginUI:NO
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             handlerCalled = YES;
                                         }];
        STFail(@"expected exception");
    } @catch (NSException *exception) {
    }
    
    FBSession *activeSession = FBSession.activeSession;
    
    assertThatBool(handlerCalled, equalToBool(NO));
    assertThat(activeSession, notNilValue());
    assertThatInt(activeSession.state, equalToInt(FBSessionStateCreatedTokenLoaded));
    
}

#pragma mark Other statics tests

- (void)testCanSetDefaultAppID {
    assertThat([FBSession defaultAppID], nilValue());
    [FBSession setDefaultAppID:kTestAppId];
    assertThat([FBSession defaultAppID], equalTo(kTestAppId));
}

- (void)testCanSetDefaultUrlSchemeSuffix {
    assertThat([FBSession defaultUrlSchemeSuffix], nilValue());
    [FBSession setDefaultUrlSchemeSuffix:kURLSchemeSuffix];
    assertThat([FBSession defaultUrlSchemeSuffix], equalTo(kURLSchemeSuffix));
}

- (void)testSessionStateDescription {
    NSArray *expectedStrings = [NSArray arrayWithObjects:
                                @"FBSessionStateCreated",
                                @"FBSessionStateCreatedTokenLoaded",
                                @"FBSessionStateCreatedOpening",
                                @"FBSessionStateOpen",
                                @"FBSessionStateOpenTokenExtended",
                                @"FBSessionStateClosedLoginFailed",
                                @"FBSessionStateClosed",
                                @"[Unknown]",
                                nil];
    FBSessionState states[] = {FBSessionStateCreated,
        FBSessionStateCreatedTokenLoaded, FBSessionStateCreatedOpening, FBSessionStateOpen,
        FBSessionStateOpenTokenExtended, FBSessionStateClosedLoginFailed, FBSessionStateClosed, -1};
    const int numTests = sizeof(states) / sizeof(FBSessionState);
    
    for (int i = 0; i < numTests; ++i) {
        NSString *description = [FBSessionUtility sessionStateDescription:states[i]];
        assertThat(description, equalTo([expectedStrings objectAtIndex:i]));
    }
}

- (void)testDescription {
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    
    NSString *description = [session description];
    assertThat(description, containsString(kTestAppId));
    assertThat(description, containsString(@"FBSessionStateCreated"));
}

- (void)testDeleteFacebookCookies {
    [self addFacebookCookieToSharedStorage];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *url = [NSURL URLWithString:[FBUtility dialogBaseURL]];
    NSArray *cookiesForFacebook = [storage cookiesForURL:url];
    
    assertThatInteger(cookiesForFacebook.count, greaterThan(@0));
    
    [FBUtility deleteFacebookCookies];
    
    cookiesForFacebook = [storage cookiesForURL:url];
    
    assertThatInteger(cookiesForFacebook.count, equalToInteger(0));
}

#pragma mark Helpers

- (BOOL)isSystemVersionAtLeast:(NSString *)desiredVersion {
    return [[[UIDevice currentDevice] systemVersion] compare:desiredVersion options:NSNumericSearch] != NSOrderedAscending;
}

- (NSHTTPCookieStorage *)addFacebookCookieToSharedStorage {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [FBUtility buildFacebookUrlWithPre:@"m."], NSHTTPCookieDomain,
                                      @"COOKIE!!!!", NSHTTPCookieName,
                                      @"/", NSHTTPCookiePath,
                                      @"hello", NSHTTPCookieValue,
                                      @"true", NSHTTPCookieSecure,
                                      nil];
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    
    [storage setCookie:cookie];
    return storage;
}

// Note: this allocs but does _not_ init the mock FBSession
// The mock session has an authorizeWithPermissions:... that does nothing -- it simulates an
// authorization attempt that has been started but has not yet received a success or failure result.
- (FBSession *)allocMockSessionWithNoOpAuth {
    FBSession *session = [FBSession alloc];
    FBSession *mockSession = [OCMockObject partialMockForObject:session];

    [[(id)mockSession stub] authorizeWithPermissions:[OCMArg any]
                                     defaultAudience:FBSessionDefaultAudienceNone
                                      integratedAuth:NO
                                           FBAppAuth:YES
                                          safariAuth:YES
                                            fallback:YES
                                       isReauthorize:NO
                                 canFetchAppSettings:YES];
    
    return mockSession;
}

- (FBSession *)allocMockSessionWithNoOpAuthThatExpectsCall:(BOOL)expect
                                               reauthorize:(BOOL)reauthorize
                                                  behavior:(FBSessionLoginBehavior)behavior
                                           defaultAudience:(FBSessionDefaultAudience)defaultAudience {
    FBSession *session = [FBSession alloc];
    FBSession *mockSession = [OCMockObject partialMockForObject:session];
    
    // Limitation of OCMock: we need to specify actual values for primitive arguments, so we need to anticipate
    // the combinations of parameters we need to mock in our tests.
    
    id stub = expect ? [(id)mockSession expect] : [(id)mockSession stub];
    [stub authorizeWithPermissions:[OCMArg any]
                          behavior:behavior
                   defaultAudience:defaultAudience
                     isReauthorize:reauthorize];

    return mockSession;
}


@end
