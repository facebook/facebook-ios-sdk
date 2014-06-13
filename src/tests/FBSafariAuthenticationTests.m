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
#import "FBAuthenticationTests.h"
#import "FBError.h"
#import "FBSession.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"


@interface FBSafariAuthenticationTests : FBAuthenticationTests
@end

@implementation FBSafariAuthenticationTests
{
    Method _originalIsRegisteredCheck;
    Method _swizzledIsRegisteredCheck;
}

+ (BOOL)isRegisteredURLSchemeReplacement:(NSString *)url
{
    return YES;
}

- (void)setUp {
    [super setUp];
    _originalIsRegisteredCheck = class_getClassMethod([FBUtility class], @selector(isRegisteredURLScheme:));
    _swizzledIsRegisteredCheck = class_getClassMethod([self class], @selector(isRegisteredURLSchemeReplacement:));
    method_exchangeImplementations(_originalIsRegisteredCheck, _swizzledIsRegisteredCheck);
}

- (void)tearDown {
    [super tearDown];
    method_exchangeImplementations(_swizzledIsRegisteredCheck, _originalIsRegisteredCheck);
    _originalIsRegisteredCheck = nil;
    _swizzledIsRegisteredCheck = nil;
}


- (void)testOpenTriesSafariAuthFirstWithFallbackToWebView {
    [self testImplOpenTriesSafariAuthFirstWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView];
}

- (void)testOpenTriesSafariAuthFirstWithNoFallbackToWebView {
    [self testImplOpenTriesSafariAuthFirstWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView];
}

- (void)testImplOpenTriesSafariAuthFirstWithBehavior:(FBSessionLoginBehavior)behavior {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:YES try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:YES try:YES results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [session openWithBehavior:behavior
            completionHandler:nil];
    
    [(id)mockSession verify];
    
    [session release];
}

- (void)testOpenDoesNotTrySafariAuthWithSystemAccount {
    [self testImplOpenDoesNotTrySafariAuthWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
                                          expectSystem:YES];
}

- (void)testOpenDoesNotTrySafariAuthWithForcingWebView {
    [self testImplOpenDoesNotTrySafariAuthWithBehavior:FBSessionLoginBehaviorForcingWebView
                                          expectSystem:NO];
}

- (void)testImplOpenDoesNotTrySafariAuthWithBehavior:(FBSessionLoginBehavior)behavior
                                        expectSystem:(BOOL)expectSystem {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:expectSystem succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:!expectSystem succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [session openWithBehavior:behavior
            completionHandler:nil];
    
    [(id)mockSession verify];
    
    [session release];
}

// The following tests validate that a successful results results in an open session,
// for each login behavior that is appropriate.
- (void)testSafariAuthSuccessWithFallbackToWebView {
    [self testImplSafariAuthSuccessWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView];
}

- (void)testSafariAuthSuccessWithNoFallbackToWebView {
    [self testImplSafariAuthSuccessWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView];
}

- (void)testSafariAuthSuccessWithUseSystemAccount {
    [self testImplSafariAuthSuccessWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
}

- (void)testImplSafariAuthSuccessWithBehavior:(FBSessionLoginBehavior)behavior {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    // We'll build a URL out of these results and send it back through handleOpenURL.
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:
                             kAuthenticationTestValidToken, @"access_token",
                             @"3600", @"expires_in",
                             nil];
    
    [self mockSession:mockSession supportSystemAccount:NO];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:YES try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:YES try:YES results:results];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    __block BOOL handlerCalled = NO;
    [session openWithBehavior:behavior completionHandler:^(FBSession *innerSession, FBSessionState status, NSError *error) {
        handlerCalled = YES;
        [_blocker signal];
    }];
    
    [_blocker waitWithTimeout:.01];
    
    [(id)mockSession verify];
    
    assertThatBool(handlerCalled, equalToBool(YES));
    assertThatInt(mockSession.state, equalToInt(FBSessionStateOpen));
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    assertThat(mockSession.accessToken, equalTo(kAuthenticationTestValidToken));
    assertThatInt(mockSession.loginType, equalToInt(FBSessionLoginTypeFacebookViaSafari));
    // TODO assert expiration date is what we set it to (within delta)
    
    [session release];
}

// The following tests validate that the 'service_disabled' error response results
// in a login dialog auth being attempted, for each login behavior that is appropriate.

// TODO: these do not work as expected; should FBSession be calling with fallback:YES?
/*
 - (void)testSafariAuthDisabledTriesLoginDialogWithFallbackToWebView {
 [self testSafariAuthDisabledTriesLoginDialogWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView];
 }
 
 - (void)testSafariAuthDisabledTriesLoginDialogWithNoFallbackToWebView {
 [self testSafariAuthDisabledTriesLoginDialogWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView];
 }
 
 - (void)testSafariAuthDisabledTriesLoginDialogWithUseSystemAccount {
 [self testSafariAuthDisabledTriesLoginDialogWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
 }
 */

- (void)testSafariAuthDisabledTriesLoginDialogWithBehavior:(FBSessionLoginBehavior)behavior {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    // We'll build a URL out of these results and send it back through handleOpenURL.
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"service_disabled", @"error",
                             nil];
    
    [self mockSession:mockSession supportSystemAccount:NO];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:YES try:NO results:results];
    [self mockSession:mockSession expectSafariAuth:YES try:YES results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:YES succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [session openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:nil];
    
    [_blocker waitWithTimeout:.01];
    
    [(id)mockSession verify];
    
    [session release];
}


// The following tests validate that a successful results results in an open session,
// for each login behavior that is appropriate.
- (void)testSafariAuthErrorWithFallbackToWebView {
    [self testImplSafariAuthErrorWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView];
}

- (void)testSafariAuthErrorWithNoFallbackToWebView {
    [self testImplSafariAuthErrorWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView];
}

- (void)testSafariAuthErrorWithUseSystemAccount {
    [self testImplSafariAuthErrorWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent];
}

- (void)testImplSafariAuthErrorWithBehavior:(FBSessionLoginBehavior)behavior {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    // We'll build a URL out of these results and send it back through handleOpenURL.
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"an error code", @"error_code",
                             @"an error reason", @"error",
                             nil];
    
    [self mockSession:mockSession supportSystemAccount:NO];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:YES try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:YES try:YES results:results];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    __block BOOL handlerCalled = NO;
    __block NSError *handlerError = nil;
    [session openWithBehavior:behavior completionHandler:^(FBSession *innerSession, FBSessionState status, NSError *error) {
        handlerCalled = YES;
        handlerError = [error retain];
        [_blocker signal];
    }];
    
    [_blocker waitWithTimeout:.01];
    
    [(id)mockSession verify];
    
    assertThatBool(handlerCalled, equalToBool(YES));
    assertThatInt(mockSession.state, equalToInt(FBSessionStateClosedLoginFailed));
    assertThat(handlerError, notNilValue());
    
    [session release];
}

// TODO finish safari auth tests

@end
