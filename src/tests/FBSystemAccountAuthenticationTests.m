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

#import "FBSystemAccountAuthenticationTests.h"
#import "FBSession.h"
#import "FBError.h"
#import "FBUtility.h"
#import <objc/objc-runtime.h>

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@implementation FBSystemAccountAuthenticationTests
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

- (void)testOpenTriesSystemAccountAuthFirstIfAvailable {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:YES succeed:NO];
    [self mockSession:mockSession supportMultitasking:NO];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:nil];
    
    [(id)mockSession verify];
    
    [session release];
}

- (void)testOpenDoesNotTrySystemAccountAuthIfUnavailable {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:NO];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:NO];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    __block NSError *handlerError = nil;
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                handlerError = error;
            }];
    
    [(id)mockSession verify];
    
    assertThat(handlerError, notNilValue());
    assertThat(handlerError.userInfo[FBErrorLoginFailedReason], equalTo(FBErrorLoginFailedReasonInlineNotCancelledValue));
    
    [session release];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithForcingWebView {
    [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSessionLoginBehaviorForcingWebView
                                            expectLoginDialog:YES];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithWithFallbackToWebView {
    [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
                                            expectLoginDialog:YES];
}

- (void)testOpenDoesNotTrySystemAccountAuthWithNoFallbackToWebView {
    [self testImplOpenDoesNotTrySystemAccountAuthWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView
                                            expectLoginDialog:NO];
}

- (void)testImplOpenDoesNotTrySystemAccountAuthWithBehavior:(FBSessionLoginBehavior)behavior
                                          expectLoginDialog:(BOOL)expectLoginDialog
{
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:NO];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:expectLoginDialog succeed:NO];
    
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

- (void)testSystemAccountSuccess {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:YES succeed:YES];
    [self mockSession:mockSession supportMultitasking:NO];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    __block NSError *handlerError = nil;
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                handlerError = error;
            }];
    
    [(id)mockSession verify];
    
    assertThat(handlerError, nilValue());
    assertThatInt(session.state, equalToInt(FBSessionStateOpen));
    assertThat(session.accessToken, equalTo(kAuthenticationTestValidToken));
    
    [session release];
}

- (void)testSystemAccountFailureGeneratesError {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:YES];
    [self mockSession:mockSession expectSystemAccountAuth:YES succeed:NO];
    [self mockSession:mockSession supportMultitasking:NO];
    [self mockSession:mockSession expectFacebookAppAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    __block NSError *handlerError = nil;
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                handlerError = error;
            }];
    
    [(id)mockSession verify];
    
    assertThat(handlerError, notNilValue());
    assertThat(handlerError.userInfo[FBErrorLoginFailedReason], equalTo(FBErrorLoginFailedReasonSystemError));
    assertThatInt(session.state, equalToInt(FBSessionStateClosedLoginFailed));
    
    [session release];
}

// TODO test untosed device continues auth process
// TODO test reauth case

- (void)testSystemAccountNotAvailableTriesNextAuthMethod {
    FBSession *mockSession = [OCMockObject partialMockForObject:[FBSession alloc]];
    
    [self mockSession:mockSession supportSystemAccount:NO];
    [self mockSession:mockSession expectSystemAccountAuth:NO succeed:NO];
    [self mockSession:mockSession supportMultitasking:YES];
    [self mockSession:mockSession expectFacebookAppAuth:YES try:YES results:nil];
    [self mockSession:mockSession expectSafariAuth:NO try:NO results:nil];
    [self mockSession:mockSession expectLoginDialogAuth:NO succeed:NO];
    
    FBSession *session = [mockSession initWithAppID:kAuthenticationTestAppId
                                        permissions:nil
                                    defaultAudience:FBSessionDefaultAudienceNone
                                    urlSchemeSuffix:nil
                                 tokenCacheStrategy:nil];
    
    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent completionHandler:nil];
    
    [(id)mockSession verify];
    
    [session release];
}


@end
