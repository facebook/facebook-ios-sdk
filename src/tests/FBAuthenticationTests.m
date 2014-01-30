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

#import "FBAuthenticationTests.h"
#import "FBSession.h"
#import "FBSystemAccountStoreAdapter.h"
#import "FBRequest.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBTestBlocker.h"
#import "FBUtility.h"

NSString *const kAuthenticationTestValidToken = @"AToken";
NSString *const kAuthenticationTestAppId = @"AnAppid";

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@interface FBSession (AuthenticationTesting)

- (void)authorizeUsingSystemAccountStore:(NSArray *)permissions
                         defaultAudience:(FBSessionDefaultAudience)defaultAudience
                           isReauthorize:(BOOL)isReauthorize;
- (BOOL)authorizeUsingFacebookApplication:(NSMutableDictionary *)params;
- (void)authorizeUsingLoginDialog:(NSMutableDictionary *)params;
- (BOOL)authorizeUsingSafari:(NSMutableDictionary *)params;
- (FBSystemAccountStoreAdapter *)getSystemAccountStoreAdapter;
- (NSString *)appBaseUrl;
- (BOOL)tryOpenURL:(NSURL *)url;

@end

// FBRequest has a helper we want to borrow.
@interface FBRequest (Testing)

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params;

@end

@interface FBAuthenticationTests () {
    id _mockFBUtility;
}
@end

@implementation FBAuthenticationTests

- (void)setUp {
    [super setUp];

    [[FBSessionTokenCachingStrategy defaultInstance] clearToken];

    FBSession.defaultAppID = kAuthenticationTestAppId;
    FBSession.defaultUrlSchemeSuffix = nil;
    FBSession.activeSession = nil;

    _blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];

    // Before every authentication test, set up a fake FBFetchedAppSettings
    // to prevent fetching app settings during FBSession authorizeWithPermissions
    _mockFBUtility = [[OCMockObject mockForClass:[FBUtility class]] retain];
    FBFetchedAppSettings *dummyFBFetchedAppSettings = [[[FBFetchedAppSettings alloc] init] autorelease];
    [[[_mockFBUtility stub] andReturn:dummyFBFetchedAppSettings] fetchedAppSettings];
    [[[_mockFBUtility stub] andReturn:nil] advertiserID];  //also stub advertiserID since that often hangs.
}

- (void)tearDown {
    [super tearDown];

    [_blocker release];
    _blocker = nil;

    [_mockFBUtility release];
    _mockFBUtility = nil;
}

- (void)mockSuccessRequestAccessToFacebookAccountStore:(NSArray *)permissions
                                       defaultAudience:(FBSessionDefaultAudience)defaultAudience
                                         isReauthorize:(BOOL)isReauthorize
                                                 appID:(NSString *)appID
                                               session:(FBSession *)session
                                               handler:(FBRequestAccessToAccountsHandler)handler {
    handler(kAuthenticationTestValidToken, nil);
}

- (void)mockFailureRequestAccessToFacebookAccountStore:(NSArray *)permissions
                                       defaultAudience:(FBSessionDefaultAudience)defaultAudience
                                         isReauthorize:(BOOL)isReauthorize
                                                 appID:(NSString *)appID
                                               session:(FBSession *)session
                                               handler:(FBRequestAccessToAccountsHandler)handler {
    NSError *error = [NSError errorWithDomain:@"TODO" code:0 userInfo:nil];
    handler(nil, error);
}

- (id)createMockSystemAccountStoreAdapter:(BOOL)succeed defaultAudience:(FBSessionDefaultAudience)defaultAudience
{
    id mockSystemAccountStoreAdapter = [OCMockObject mockForClass:[FBSystemAccountStoreAdapter class]];

    SEL selectorToCall = nil;
    if (succeed) {
        selectorToCall = @selector(mockSuccessRequestAccessToFacebookAccountStore:defaultAudience:isReauthorize:appID:session:handler:);
    } else {
        selectorToCall = @selector(mockFailureRequestAccessToFacebookAccountStore:defaultAudience:isReauthorize:appID:session:handler:);
    }

    // Now actually mock the call to run our handler.
    [[[mockSystemAccountStoreAdapter stub] andCall:selectorToCall onObject:self]
     requestAccessToFacebookAccountStore:[OCMArg any]
     defaultAudience:defaultAudience
     isReauthorize:NO
     appID:[OCMArg any]
     session:[OCMArg any]
     handler:[OCMArg any]];

    return mockSystemAccountStoreAdapter;
}

- (void)mockSession:(id)mockSession supportSystemAccount:(BOOL)supportSystemAccount {
    [[[[_mockFBUtility stub] classMethod] andReturnValue:OCMOCK_VALUE(supportSystemAccount)] isSystemAccountStoreAvailable];
}


- (void)mockSession:(id)mockSession
expectSystemAccountAuth:(BOOL)expect
            succeed:(BOOL)succeed {
    FBSessionDefaultAudience defaultAudience = FBSessionDefaultAudienceNone;

    id expectOrReject = nil;
    if (expect) {
        expectOrReject = [[mockSession expect] andForwardToRealObject];

        id mockSystemAccountStoreAdapter =[self createMockSystemAccountStoreAdapter:succeed
                                                                    defaultAudience:defaultAudience];

        [[[mockSession stub] andReturn:mockSystemAccountStoreAdapter] getSystemAccountStoreAdapter];
    } else {
        expectOrReject = [mockSession reject];
    }
    [expectOrReject authorizeUsingSystemAccountStore:[OCMArg any]
                                     defaultAudience:defaultAudience
                                       isReauthorize:NO];
}

- (void)mockSession:(id)mockSession supportMultitasking:(BOOL)supportMultitasking {
    [[[[_mockFBUtility stub] classMethod] andReturnValue:OCMOCK_VALUE(supportMultitasking)] isMultitaskingSupported];
}

- (void)mockSession:(id)mockSession
expectFacebookAppAuth:(BOOL)expect
                try:(BOOL)try
            results:(NSDictionary *)results {
    if (expect) {
        // Note: we call the real implementation, but always return 'try' regardless of what it does
        id mock = [[[mockSession expect] andForwardToRealObject] andReturnValue:OCMOCK_VALUE(try)];

        // We stub out tryOpenURL: below, and we fake a response (if we were told to)
        if (try && results) {
            mock = [mock andDo:^(NSInvocation *invocation) {
                dispatch_after(DISPATCH_TIME_NOW, dispatch_get_current_queue(), ^{
                    NSString *baseURL = [NSString stringWithFormat:@"fb%@://authorize", kAuthenticationTestAppId];

                    // Cheat and use FBRequest's helper
                    NSString *urlString = [FBRequest serializeURL:baseURL params:results];
                    NSURL *url = [NSURL URLWithString:urlString];

                    // Assume the app developer calls [FBSession handleOpenURL] on the correct session.
                    [mockSession handleOpenURL:url];
                });
            }];
        }

        // We mock authorizeUsingFacebookApplication rather than tryOpenURL to avoid conflicting
        // with mockSession:expectSafariAuth:try:succeed:
        [mock authorizeUsingFacebookApplication:[OCMArg any]];

        // Make tryOpenURL: a no-op so it doesn't actually call out.
        BOOL no = NO;
        [[[mockSession stub] andReturnValue:OCMOCK_VALUE(no)] tryOpenURL:[OCMArg any]];
    } else {
        [[mockSession reject] authorizeUsingFacebookApplication:[OCMArg any]];
    }
}

- (void)mockSession:(id)mockSession
   expectSafariAuth:(BOOL)expect
                try:(BOOL)try
            results:(NSDictionary *)results {
    // TODO succeed
    if (expect) {
        // Note: we call the real implementation, but always return 'try' regardless of what it does
        id mock = [[[mockSession expect] andForwardToRealObject] andReturnValue:OCMOCK_VALUE(try)];

        // We stub out tryOpenURL: below, and we fake a response (if we were told to)
        if (try && results) {
            mock = [mock andDo:^(NSInvocation *invocation) {
                dispatch_after(DISPATCH_TIME_NOW, dispatch_get_current_queue(), ^{
                    NSString *baseURL = [NSString stringWithFormat:@"fb%@://authorize", kAuthenticationTestAppId];

                    // Cheat and use FBRequest's helper
                    NSString *urlString = [FBRequest serializeURL:baseURL params:results];
                    NSURL *url = [NSURL URLWithString:urlString];

                    // Assume the app developer calls [FBSession handleOpenURL] on the correct session.
                    [mockSession handleOpenURL:url];
                });
            }];
        }

        // We mock authorizeUsingFacebookApplication rather than tryOpenURL to avoid conflicting
        // with mockSession:expectFacebookAppAuth:try:succeed:
        [mock authorizeUsingSafari:[OCMArg any]];

        // Make tryOpenURL: a no-op so it doesn't actually call out.
        BOOL no = NO;
        [[[mockSession stub] andReturnValue:OCMOCK_VALUE(no)] tryOpenURL:[OCMArg any]];
    } else {
        [[mockSession reject] authorizeUsingSafari:[OCMArg any]];
    }
}

- (void)mockSession:(id)mockSession expectLoginDialogAuth:(BOOL)expect succeed:(BOOL)succeed {
    // TODO succeed
    if (expect) {
        [[mockSession expect] authorizeUsingLoginDialog:[OCMArg any]];
    } else {
        [[mockSession reject] authorizeUsingLoginDialog:[OCMArg any]];
    }
}

@end
