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

#import <objc/runtime.h>

#import "FBAccessTokenData+Internal.h"
#import "FBError.h"
#import "FBGraphUser.h"
#import "FBInMemoryFBSessionTokenCachingStrategy.h"
#import "FBInternalSettings.h"
#import "FBRequest.h"
#import "FBSession+Internal.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBSessionUtility.h"
#import "FBSystemAccountStoreAdapter.h"
#import "FBTestBlocker.h"
#import "FBTests.h"
#import "FBUtility.h"

static NSString *kURLSchemeSuffix = @"URLSuffix";

// We test quite a few deprecated properties.
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBSession (FBSessionTests)

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
- (void)callReauthorizeHandlerAndClearState:(NSError *)error updateDeclinedPermissions:(BOOL)updateDeclinedPermissions;

@end

#pragma mark - Test suite

@interface FBSessionTests : FBTests
@end

@implementation FBSessionTests
{
    FBTestBlocker *_blocker;
    Method _originalIsRegisteredCheck;
    Method _swizzledIsRegisteredCheck;

    Method _originalTokenCachingStrategyDefaultInstance;
    Method _swizzledTokenCachingStrategyDefaultInstance;
    id _mockFBSessionTokenCachingStrategy;
    FBInMemoryFBSessionTokenCachingStrategy *_inMemoryFBSessionTokenCachingStrategy;
}

+ (BOOL)isRegisteredURLSchemeReplacement:(NSString *)url
{
    return YES;
}

- (void)setUp {
    [super setUp];
    _inMemoryFBSessionTokenCachingStrategy = [[FBInMemoryFBSessionTokenCachingStrategy alloc] init];

    // Default token caching strategy now uses keychain which requires emulator services running
    // and is not supported by xctool logic tests (https://github.com/facebook/xctool/issues/269)
    // So for these tests let's swizzle out the defaultInstance with an in memory one.
    _mockFBSessionTokenCachingStrategy = [OCMockObject mockForClass:[FBSessionTokenCachingStrategy class]];
    [[[_mockFBSessionTokenCachingStrategy stub] andReturn:_inMemoryFBSessionTokenCachingStrategy] defaultInstance];

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
    [_mockFBSessionTokenCachingStrategy stopMocking];
    [_inMemoryFBSessionTokenCachingStrategy release];
}

#pragma mark Init tests

- (void)testInitWithoutDefaultAppIDThrows {
    @try {
        [[FBSession alloc] init];
        XCTFail(@"should have gotten exception");
    } @catch (NSException *exception) {
    }
}

- (void)testInitWithDefaultAppIDSetsDefaultValues {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];

    XCTAssertNil(session.refreshDate);

    XCTAssertEqual(FBSessionLoginTypeNone, session.loginType);
    
    [session release];
}

- (void)testInitWithDefaultAppIDSetsAppID {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];

    XCTAssertTrue([kTestAppId isEqualToString:session.appID]);
    
    [session release];
}

- (void)testInitWithDefaultAppIDSetsState {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBSession *session = [[FBSession alloc] init];

    XCTAssertFalse(session.isOpen);
    XCTAssertEqual(FBSessionStateCreated, session.state);
    
    [session release];
}

- (void)testInitWithPermissionsSetsDefaultValues {
    [FBSession setDefaultAppID:kTestAppId];
    
    NSArray *permissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    FBSession *session = [[FBSession alloc] initWithPermissions:permissions];

    XCTAssertNil(session.refreshDate);
    XCTAssertEqual(FBSessionLoginTypeNone, session.loginType);
    
    [session release];
}

- (void)testInitWithPermissionsSetsPermissions {
    [FBSession setDefaultAppID:kTestAppId];
    
    NSArray *permissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    FBSession *session = [[FBSession alloc] initWithPermissions:permissions];

    XCTAssertEqualObjects(permissions, session.permissions);
    
    [session release];
}

- (void)testInitWithoutUrlSchemeSuffixUsesDefault {
    FBSession.defaultUrlSchemeSuffix = @"defaultsuffix";
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    
    XCTAssertTrue([@"defaultsuffix" isEqualToString:session.urlSchemeSuffix]);
    
    [session release];
}

- (void)testInitWithUrlSchemeSuffixOverridesDefault {
    FBSession.defaultUrlSchemeSuffix = @"defaultsuffix";
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:@"asuffix"
                                       tokenCacheStrategy:nil];

    XCTAssertTrue([@"asuffix" isEqualToString:session.urlSchemeSuffix]);

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

    XCTAssertFalse(session.isOpen);
    XCTAssertEqual(FBSessionStateCreated, session.state);
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
    
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, session.state);
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

    XCTAssertTrue([session.refreshDate timeIntervalSinceNow] < 5000);
    XCTAssertEqual(FBSessionLoginTypeNone, session.loginType);
    
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
    
    XCTAssertFalse(session.isOpen);
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, session.state);
    
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

    XCTAssertTrue([kTestAppId isEqualToString:session.appID]);
    
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

    XCTAssertTrue([mockToken.accessToken isEqualToString:session.accessToken]);
    
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

    XCTAssertEqualObjects(refreshDate, session.refreshDate);
    
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
    
    XCTAssertEqual(FBSessionLoginTypeWebView, session.loginType);
    
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

    XCTAssertEqualObjects(mockToken.expirationDate, session.expirationDate);
    
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

    XCTAssertEqualObjects(tokenPermissions, session.permissions);
    
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
    
    XCTAssertEqualObjects(tokenPermissions, session.permissions);
    
    [session release];
}

- (void)testInitWithValidTokenAndNonSubsetOfCachedPermissionsDoesUseCachedToken {
    FBAccessTokenData *mockToken = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"permission1", @"permission2", nil];
    [[[(id)mockToken stub] andReturn:tokenPermissions] permissions];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:mockToken];

    NSArray *sessionPermissions = [NSArray arrayWithObject:@"permission3"];
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:sessionPermissions
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    
    XCTAssertEqualObjects(tokenPermissions, session.permissions);
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, session.state);
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
    
    XCTAssertEqual(FBSessionStateCreatedOpening, mockSession.state);
    XCTAssertFalse(handlerCalled);
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
    [session openWithCompletionHandler:^(FBSession *innerSession, FBSessionState status, NSError *error) {
        handlerCalled = YES;
    }];
    
    XCTAssertEqual(FBSessionStateOpen, session.state);
    XCTAssertTrue(handlerCalled);
    
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

    XCTAssertEqual(FBSessionStateOpen, session.state);

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
    
    XCTAssertEqual(FBSessionStateOpen, session.state);
    
    @try {
        [session openWithCompletionHandler:nil];
        XCTFail(@"should have gotten an exception");
    } @catch (NSException *exception) {
    }
    
    [session release];
    
}

#pragma mark URL parameters handling tests

// These tests test parameters decoding through handleOpenURL:

- (void) testDeniedPermissionsParamFromHandleOpenURL {

    [FBSettings setDefaultAppID:kTestAppId];
    FBSession *session = [OCMockObject partialMockForObject:[FBSession alloc]];
    [(FBSession *)[[(id)session stub] andReturnValue:@(FBSessionStateCreatedOpening)] state];
    session = [session initWithAppID:kTestAppId
                         permissions:nil
                     defaultAudience:FBSessionDefaultAudienceNone
                     urlSchemeSuffix:nil
                  tokenCacheStrategy:nil];

    NSString *url = @"fbAnAppId://authorize#e2e=%7B%22submit_0%22%3A1401237872226%7D&expires_in=5184000"
        "&state=%7B%22is_open_session%22%3Atrue%2C%22is_active_session%22%3Atrue%2C"
        "%22com.facebook.sdk_client_state%22%3Atrue%2C%223_method%22%3A"
        "%22fb_application_web_auth%22%2C%220_auth_logger_id%22%3A%22ABA039F1-7650-4B16-A195-AE249915532E%22%7D"
        "&granted_scopes=public_profile%2Cread_mailbox"
        "&access_token=FOO&denied_scopes=email%2Cuser_relationships";

    [session handleOpenURL:[NSURL URLWithString:url]];

    NSArray *expectedPermissions = [NSArray arrayWithObjects:@"public_profile", @"read_mailbox", nil];
    XCTAssertEqualObjects(expectedPermissions, session.permissions, @"");

    NSArray *expectedDeclinedPermissions = [NSArray arrayWithObjects:@"email", @"user_relationships", nil];
    XCTAssertEqualObjects(expectedDeclinedPermissions, session.declinedPermissions, @"");

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
    XCTAssertEqual(FBSessionStateCreated, session.state);
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
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, session.state);
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
    XCTAssertEqual(FBSessionStateClosedLoginFailed, session.state);
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
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, session.state);
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
    
    XCTAssertFalse(session.isOpen);
    
    @try {
        [session reauthorizeWithPermissions:nil
                                   behavior:FBSessionLoginBehaviorWithFallbackToWebView
                          completionHandler:nil];
        XCTFail(@"expected exception");
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
    XCTAssertTrue(session.isOpen);
    
    FBSessionRequestPermissionResultHandler handler = ^(FBSession *innerSession, NSError *error) {
    };
    
    // Because our session is mocked to do nothing with auth requests, it will stay in a "pending"
    // reauth state after this call.
    [session requestNewReadPermissions:nil completionHandler:handler];
    
    @try {
        [session requestNewReadPermissions:nil completionHandler:handler];
        XCTFail(@"expected exception");
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
    
    XCTAssertTrue(session.isOpen);
    
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
    XCTAssertTrue(session.isOpen);
    
    // Because our session is mocked to do nothing with auth requests, it will stay in a "pending"
    // reauth state after this call.
    [session requestNewReadPermissions:nil completionHandler:^(FBSession *innerSession, NSError *error) {
    }];
    
    BOOL caughtException = NO;
    @try {
        [session requestNewReadPermissions:nil completionHandler:nil];
        XCTFail(@"expected exception");
    } @catch (NSException *exception) {
        caughtException = YES;
    }
    XCTAssertTrue(caughtException, @"expected exception when requesting more permissions.");
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
        XCTFail(@"expected exception");
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
    
    XCTAssertTrue(session.isOpen);
    
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
    
    XCTAssertTrue(session.isOpen);
    
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
    [[(id)mockSession reject] callReauthorizeHandlerAndClearState:[OCMArg any] updateDeclinedPermissions:YES];
    [[(id)mockSession reject] callReauthorizeHandlerAndClearState:[OCMArg any] updateDeclinedPermissions:NO];

    [FBSettings setDefaultAppID:kTestAppId];
    
    [session handleDidBecomeActive];
    
    XCTAssertEqual(FBSessionStateCreated, session.state);
}

- (void)testIsMultitaskingSupported {
    UIDevice *device = [UIDevice currentDevice];
    BOOL shouldBeSupported = [device respondsToSelector:@selector(isMultitaskingSupported)] &&
        [device isMultitaskingSupported];

    XCTAssertEqual(shouldBeSupported, [FBUtility isMultitaskingSupported]);
}

- (void)testWillAttemptToExtendToken {
    FBAccessTokenData *token = [FBAccessTokenData createTokenFromString:@"token"
                                                            permissions:nil
                                                         expirationDate:[NSDate distantFuture]
                                                              loginType:FBSessionLoginTypeFacebookApplication
                                                            refreshDate:[NSDate dateWithTimeIntervalSince1970:0]
                                                 permissionsRefreshDate:nil
                                                                  appID:kTestAppId];
    
    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:token];
    
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    [session openWithCompletionHandler:nil];
    
    BOOL shouldExtend = [session shouldExtendAccessToken];
    
    XCTAssertTrue(shouldExtend);
}


#pragma mark Active session tests

- (void)testActiveSessionDefaultsToNewCreatedSession {
    [FBSession setDefaultAppID:kTestAppId];
    
    XCTAssertNil(FBSession.activeSessionIfOpen);
    FBSession *session = FBSession.activeSession;
    XCTAssertNotNil(session);
    XCTAssertEqual(FBSessionStateCreated, session.state);
}

- (void)testSetActiveSession {
    [FBSession setDefaultAppID:kTestAppId];

    XCTAssertNil(FBSession.activeSessionIfOpen);

    FBSession *originalActiveSession = FBSession.activeSession;
    XCTAssertNotNil(originalActiveSession);
    
    FBSession *newSession = [[FBSession alloc] init];
    FBSession.activeSession = newSession;
    
    FBSession *activeSession = [FBSession activeSession];
    XCTAssertNotNil(activeSession);
    XCTAssertEqualObjects(newSession, activeSession);
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
        XCTFail(@"expected exception");
    } @catch (NSException *exception) {
    }
}

- (void)testOpenActiveSessionWithNoTokenOrUIStaysInCreated {
    [FBSession setDefaultAppID:kTestAppId];

    BOOL result = [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    FBSession *activeSession = FBSession.activeSession;

    XCTAssertFalse(result);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateCreated, activeSession.state);
}

- (void)testOpenActiveSessionWithValidTokenAndNoUISucceeds {
    [FBSession setDefaultAppID:kTestAppId];

    FBAccessTokenData *token = [self createValidMockToken];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];

    BOOL result = [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    FBSession *activeSession = FBSession.activeSession;
    
    XCTAssertTrue(result);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateOpen, activeSession.state);
    XCTAssertTrue([token isEqualToAccessTokenData:activeSession.accessTokenData]);
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
    
    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateOpen, activeSession.state);
    XCTAssertTrue([token isEqualToAccessTokenData:activeSession.accessTokenData]);
    
}

- (void)testOpenActiveSessionRequestingMorePermissionsThanTokenPasses {
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
    
    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateOpen, activeSession.state);
    
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
    
    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateOpen, activeSession.state);
    XCTAssertTrue([token isEqualToAccessTokenData:activeSession.accessTokenData]);
}

- (void)testOpenSessionViaSystemAccountWithReadRequestingReadAndWritePermissionFails {
    [FBSession setDefaultAppID:kTestAppId];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"permission1", @"publish_permission2", nil];
    __block BOOL handlerCalled = NO;
    
    @try {
        FBSession *session = [[[FBSession alloc] initWithPermissions:requestedPermissions] autorelease];
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                completionHandler:^(FBSession *innerSession, FBSessionState status, NSError *error) {
                    handlerCalled = YES;
                }];
        XCTFail(@"expected exception");
    } @catch (NSException *exception) {
    }
    
    FBSession *activeSession = FBSession.activeSession;
    
    XCTAssertFalse(handlerCalled);
    XCTAssertNotNil(activeSession);
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
    
    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateOpen, activeSession.state);
    XCTAssertTrue([token isEqualToAccessTokenData:activeSession.accessTokenData]);
}

- (void)testOpenSessionViaSystemAccountWithPublishAndNoDefaultAudienceFails {
    [FBSession setDefaultAppID:kTestAppId];
    
    FBAccessTokenData *token = [self createValidMockToken];
    NSArray *tokenPermissions = [NSArray arrayWithObjects:@"publish_permission1", nil];
    [[[(id)token stub] andReturn:tokenPermissions] permissions];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];
    
    NSArray *requestedPermissions = [NSArray arrayWithObjects:@"publish_permission1", nil];
    __block BOOL handlerCalled = NO;
    
    @try {
        FBSession *session = [[[FBSession alloc] initWithPermissions:requestedPermissions] autorelease];
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:^(FBSession *innerSession, FBSessionState status, NSError *error) {
            handlerCalled = YES;
        }];
        XCTFail(@"expected exception");
    } @catch (NSException *exception) {
    }
    
    FBSession *activeSession = FBSession.activeSession;
    
    XCTAssertFalse(handlerCalled);
    XCTAssertNotNil(activeSession);
    XCTAssertEqual(FBSessionStateCreatedTokenLoaded, activeSession.state);
    
}

- (void)testV2PermissionsRefresh
{
    [FBSession setDefaultAppID:kTestAppId];

    FBAccessTokenData *token = [self createValidMockToken];
    [[FBSessionTokenCachingStrategy defaultInstance] cacheFBAccessTokenData:token];

    BOOL result = [FBSession openActiveSessionWithAllowLoginUI:NO];

    XCTAssertTrue(result);
    FBSession *target = [FBSession activeSession];
    id mockResponse = @{ @"data" : @[ @{@"permission":@"user_likes", @"status":@"granted"},
                                      @{@"permission":@"user_friends", @"status":@"denied"}
                                      ] };
    [target handleRefreshPermissions:mockResponse];
    XCTAssertEqual(1, target.permissions.count);
    XCTAssertTrue([target.permissions containsObject:@"user_likes"]);
    XCTAssertTrue([target.declinedPermissions containsObject:@"user_friends"]);
}

#pragma mark Other statics tests

- (void)testCanSetDefaultAppID {
    XCTAssertNil([FBSession defaultAppID]);
    [FBSession setDefaultAppID:kTestAppId];
    XCTAssertTrue([kTestAppId isEqualToString:[FBSession defaultAppID]]);
}

- (void)testCanSetDefaultUrlSchemeSuffix {
    XCTAssertNil([FBSession defaultUrlSchemeSuffix]);
    [FBSession setDefaultUrlSchemeSuffix:kURLSchemeSuffix];
    XCTAssertTrue([kURLSchemeSuffix isEqualToString:[FBSession defaultUrlSchemeSuffix]]);
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
        XCTAssertTrue([description isEqualToString:expectedStrings[i]]);
    }
}

- (void)testDescription {
    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    
    NSString *description = [session description];
    XCTAssertTrue([description rangeOfString:kTestAppId].location != NSNotFound);
    XCTAssertTrue([description rangeOfString:@"FBSessionStateCreated"].location != NSNotFound);
}

- (void)testDeleteFacebookCookies {
    [self addFacebookCookieToSharedStorage];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSURL *url = [NSURL URLWithString:[FBUtility dialogBaseURL]];
    NSArray *cookiesForFacebook = [storage cookiesForURL:url];

    XCTAssertGreaterThan(cookiesForFacebook.count, 0);
    
    [FBUtility deleteFacebookCookies];
    
    cookiesForFacebook = [storage cookiesForURL:url];

    XCTAssertEqual(0, cookiesForFacebook.count);
}

- (void)testFetchUserID {
    FBAccessTokenData *token = [FBAccessTokenData createTokenFromString:@"token"
                                                            permissions:nil
                                                    declinedPermissions:nil
                                                         expirationDate:[NSDate distantFuture]
                                                              loginType:FBSessionLoginTypeFacebookApplication
                                                            refreshDate:[NSDate dateWithTimeIntervalSince1970:0]
                                                 permissionsRefreshDate:nil
                                                                  appID:kTestAppId
                                                                 userID:@"4"];

    FBSessionTokenCachingStrategy *mockStrategy = [self createMockTokenCachingStrategyWithToken:token];

    FBSession *session = [[FBSession alloc] initWithAppID:kTestAppId
                                              permissions:nil
                                          defaultAudience:FBSessionDefaultAudienceNone
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:mockStrategy];
    [session openWithCompletionHandler:nil];

    XCTAssertTrue([@"4" isEqualToString:session.accessTokenData.userID]);

}

#pragma mark Helpers

- (BOOL)isSystemVersionAtLeast:(NSString *)desiredVersion {
    return [[[UIDevice currentDevice] systemVersion] compare:desiredVersion options:NSNumericSearch] != NSOrderedAscending;
}

- (NSHTTPCookieStorage *)addFacebookCookieToSharedStorage {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

    NSString *domain = [[FBUtility buildFacebookUrlWithPre:@"m."] stringByDeletingLastPathComponent];
    NSDictionary *cookieProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      domain, NSHTTPCookieDomain,
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
