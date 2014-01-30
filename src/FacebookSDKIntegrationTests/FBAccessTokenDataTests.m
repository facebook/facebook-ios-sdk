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

#import "FacebookSDK.h"
#import "FBAccessTokenDataTests.h"
#import "FBTestBlocker.h"
#import "FBSessionTokenCachingStrategy.h"
#import "FBAccessTokenData+Internal.h"

#if defined(FACEBOOKSDK_SKIP_FBACCESSTOKEN_TESTS)

#pragma message ("warning: Skipping FBAccessTokenTests")

#else

typedef void (^VoidBlock)(NSString *keyPath, id object, NSDictionary *change, id context);

// An adapter to provde a KVO delegate that supports block idiom.
@interface KVOHelper : NSObject {
    VoidBlock _handler;
}

- (KVOHelper *)initWithBlock:(VoidBlock)handler;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end

@implementation KVOHelper
- (KVOHelper *)initWithBlock:(VoidBlock)handler {
    if ((self = [super init])) {
        _handler = Block_copy(handler);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    _handler(keyPath, object, change, context);
}

- (void)dealloc {
    Block_release(_handler);

    [super dealloc];
}

@end

@implementation FBAccessTokenDataTests

// Verifies caching and fetching of FBAccessTokenData.
- (void)testCachingStrategy {
    FBAccessTokenData *randomToken = [FBAccessTokenData createTokenFromString:@"token"
                                                                  permissions:[NSArray arrayWithObjects:@"perm1", @"perm2", nil]
                                                               expirationDate:[NSDate date]
                                                                    loginType:FBSessionLoginTypeFacebookViaSafari
                                                                  refreshDate:nil];

    FBSessionTokenCachingStrategy *cachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
    [cachingStrategy cacheFBAccessTokenData:randomToken];

    FBAccessTokenData *cachedToken = [cachingStrategy fetchFBAccessTokenData];

    STAssertEquals(randomToken.accessToken, cachedToken.accessToken, @"accessToken does not match");
    STAssertEquals(randomToken.loginType, cachedToken.loginType, @"loginType does not match");
    STAssertTrue([randomToken.permissions isEqualToArray:cachedToken.permissions], @"permissions does not match");
    STAssertTrue([randomToken.expirationDate isEqualToDate:cachedToken.expirationDate], @"expirationDate does not match");
}

// Verifies no token fetched when cache is empty.
- (void)testCachingStrategyWhenEmpty {
    FBSessionTokenCachingStrategy *cachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
    [cachingStrategy clearToken];

    FBAccessTokenData *cachedToken = [cachingStrategy fetchFBAccessTokenData];
    STAssertNil(cachedToken, @"expected nil token but found %@", cachedToken);
}

// Verifies that session init can read everything as expected from the cache.
- (void)testCachingStrategyAndSessionInit {
    NSArray *expectedPermissions = @[@"email", @"publish_stream"];
    NSDictionary *dictionary = @{
                                 FBTokenInformationTokenKey : @"token",
                                 FBTokenInformationExpirationDateKey : [NSDate dateWithTimeIntervalSince1970:1893456000],
                                 FBTokenInformationPermissionsKey : expectedPermissions,
                                 FBTokenInformationLoginTypeLoginKey : [NSNumber numberWithInt:FBSessionLoginTypeFacebookViaSafari],
                                 FBTokenInformationRefreshDateKey : [NSDate dateWithTimeIntervalSince1970:1356998400],
                                 FBTokenInformationPermissionsRefreshDateKey : [NSDate dateWithTimeIntervalSince1970:1356998401],
                                 };

    FBAccessTokenData *randomToken = [FBAccessTokenData createTokenFromDictionary:dictionary];
    FBSessionTokenCachingStrategy *cachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
    [cachingStrategy cacheFBAccessTokenData:randomToken];

    FBSession *session = [[FBSession alloc] initWithAppID:@"appid"
                                              permissions:@[@"email"]
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    STAssertEquals(FBSessionStateCreatedTokenLoaded, session.state, @"Expected session to have init from cache");

    FBAccessTokenData *fetchedToken = session.accessTokenData;

    STAssertNotNil(fetchedToken, @"Expected session to have token data");

    STAssertEqualObjects(@"token", fetchedToken.accessToken, @"accessToken does not match");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1893456000], fetchedToken.expirationDate, @"expirationDate does not match");
    STAssertEqualObjects(expectedPermissions, fetchedToken.permissions, @"permissions does not match");
    STAssertEquals(FBSessionLoginTypeFacebookViaSafari, fetchedToken.loginType, @"loginType does not match");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1356998400], fetchedToken.refreshDate, @"refreshDate does not match");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1356998401], fetchedToken.permissionsRefreshDate, @"permissionsRefreshDate does not match");
}
// Verifies that session init can read everything as expected from the cache for old cache entries that use isFacebookLogin
- (void)testCachingStrategyAndSessionInit_IsFacebookLogin {
    NSArray *expectedPermissions = @[@"email", @"publish_stream"];
    NSDictionary *dictionary = @{
                                 FBTokenInformationTokenKey : @"token",
                                 FBTokenInformationExpirationDateKey : [NSDate dateWithTimeIntervalSince1970:1893456000],
                                 FBTokenInformationPermissionsKey : expectedPermissions,
                                 FBTokenInformationIsFacebookLoginKey : [NSNumber numberWithBool:YES],
                                 FBTokenInformationRefreshDateKey : [NSDate dateWithTimeIntervalSince1970:1356998400]
                                 };

    FBAccessTokenData *randomToken = [FBAccessTokenData createTokenFromDictionary:dictionary];
    FBSessionTokenCachingStrategy *cachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
    [cachingStrategy cacheFBAccessTokenData:randomToken];

    FBSession *session = [[FBSession alloc] initWithAppID:@"appid"
                                              permissions:@[@"email"]
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];
    STAssertEquals(FBSessionStateCreatedTokenLoaded, session.state, @"Expected session to have init from cache");

    FBAccessTokenData *fetchedToken = session.accessTokenData;

    STAssertNotNil(fetchedToken, @"Expected session to have token data");

    STAssertEqualObjects(@"token", fetchedToken.accessToken, @"accessToken does not match");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1893456000], fetchedToken.expirationDate, @"expirationDate does not match");
    STAssertEqualObjects(expectedPermissions, fetchedToken.permissions, @"permissions does not match");
    STAssertEquals(FBSessionLoginTypeFacebookApplication, fetchedToken.loginType, @"loginType does not match - this should have been set based on isFacebookLogin cache entry");
    STAssertEqualObjects([NSDate dateWithTimeIntervalSince1970:1356998400], fetchedToken.refreshDate, @"refreshDate does not match");
}
// Verifies nil when not providing a token string.
- (void)testRequiredParameters {
    STAssertNil([FBAccessTokenData createTokenFromString:@""
                                             permissions:nil
                                          expirationDate:nil
                                               loginType:FBSessionLoginTypeNone
                                             refreshDate:nil],
                @"expected nil token");
    STAssertNil([FBAccessTokenData createTokenFromString:nil
                                             permissions:nil
                                          expirationDate:nil
                                               loginType:FBSessionLoginTypeNone
                                             refreshDate:nil],
                @"expected nil token");

}

- (void)testSessionOpenFromCacheWithKVO {
    // Stuff a random token into the cache. Note it doesn't have to be real since we won't issue any real requests
    // with it.
    NSDate *date = [NSDate distantFuture];
    FBAccessTokenData *randomToken = [FBAccessTokenData createTokenFromString:@"token"
                                                                  permissions:[NSArray arrayWithObjects:@"perm1", @"perm2", nil]
                                                               expirationDate:date
                                                                    loginType:FBSessionLoginTypeFacebookViaSafari
                                                                  refreshDate:nil];
    FBSessionTokenCachingStrategy *cachingStrategy = [FBSessionTokenCachingStrategy defaultInstance];
    [cachingStrategy cacheFBAccessTokenData:randomToken];

    // Now init a new session instance and attach KVO behavior.
    FBSession *target = [[FBSession alloc] initWithAppID:@"appid" permissions:nil defaultAudience:FBSessionDefaultAudienceNone urlSchemeSuffix:nil tokenCacheStrategy:nil];


    // Build a dictionary of expected kvo values that we will remove when encountered.
    NSMutableDictionary *expectedKvoValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                              [NSNumber numberWithInt:FBSessionStateOpen], @"state",
                                              [NSNumber numberWithBool:YES], @"isOpen",
                                              nil];

    FBTestBlocker *blocker = [[[FBTestBlocker alloc] initWithExpectedSignalCount:[expectedKvoValues count]] autorelease];
    KVOHelper *kvoHelper = [[KVOHelper alloc] initWithBlock:^(NSString *keyPath, id object, NSDictionary *change, id context) {
        STAssertEqualObjects(expectedKvoValues[keyPath], change[NSKeyValueChangeNewKey], @"value did not match expected for %@",keyPath);
        [expectedKvoValues removeObjectForKey:keyPath];

        [blocker signal];
    }];

    // Note we only observe isOpen and state since the other notable KVO vars were changed
    // during init (since this test case is initializing from cache).
    [target addObserver:kvoHelper forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    [target addObserver:kvoHelper forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];

    // Now open the session and it should transition to open (and hit our kvo helper block for each keypath)
    [target openWithBehavior:FBSessionLoginBehaviorWithNoFallbackToWebView completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        STAssertNil(error, @"Unexpected error in session state change handler: %@", error);
    }];

    // Wait until we get the expected KVO events finish.
    STAssertTrue([blocker waitWithTimeout:60], @"blocked timed out when it should have been signalled awake. Still expecting %@", expectedKvoValues);

    [target removeObserver:kvoHelper forKeyPath:@"state"];
    [target removeObserver:kvoHelper forKeyPath:@"isOpen"];

    [target release];
    [kvoHelper release];
    [expectedKvoValues release];
}

- (void)testSessionOpenThenReauthThenCloseWithKVO {
    // Create a session and attach KVO observer.
    FBTestSession *target = [[FBTestSession sessionWithPrivateUserWithPermissions:nil] retain];

    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];

    __block int expectedState = 0; // simple state flag, 0 = opening, 1 = request new permissions, 2 = closing.

    // Build a dictionary of expected # of kvo occurences per path
    NSMutableDictionary *expectedKvoValuesForOpening =
    [[NSMutableDictionary alloc] initWithObjectsAndKeys:
     @2, @"state",
     @1, @"isOpen",
     @1, @"expirationDate",
     @1, @"accessToken",
     @1, @"accessTokenData",
     nil];
    NSMutableDictionary *expectedKvoValuesForNewPermissions =
    [[NSMutableDictionary alloc] initWithObjectsAndKeys:
     @1, @"state",
     @1, @"expirationDate",
     @1, @"accessToken",
     @1, @"accessTokenData",
     nil];
    NSMutableDictionary *expectedKvoValuesForClosing =
    [[NSMutableDictionary alloc] initWithObjectsAndKeys:
     @1, @"state",
     @1, @"isOpen",
     @1, @"expirationDate",
     @1, @"accessToken",
     @1, @"accessTokenData",
     nil];

    __block NSMutableString *expectedToken = nil;

    // Essentially this kvoHelper will perform the expect kvo verification
    // by checking off the expected occurences from the dictionary which
    // is based upon the current state transition.
    KVOHelper *kvoHelper = [[KVOHelper alloc] initWithBlock:^(NSString *keyPath, id object, NSDictionary *change, id context) {
        // Use the appropriate dictionary.
        NSMutableDictionary *dictionaryPointer = (expectedState == 0) ? expectedKvoValuesForOpening :
        (expectedState == 1) ? expectedKvoValuesForNewPermissions : expectedKvoValuesForClosing;

        // Count off the occurence, and remove it if it's done.
        NSNumber *count = dictionaryPointer[keyPath];
        if (!count || [count intValue] <= 0) {
            STFail(@"unexpected KVO for of %@ (%@) in state %d", keyPath, change, expectedState);
        } else {
            int newCount = [count intValue] - 1;
            if (newCount == 0) {
                [dictionaryPointer removeObjectForKey:keyPath];
            } else {
                [dictionaryPointer setObject:[NSNumber numberWithInt:newCount] forKey:keyPath];
            }
        }

        // Now do specific inspection for certain states.
        switch (expectedState) {
                // For unit test simplicity we only inspect the access tokens key in depth.
            case 0:
                if ([keyPath isEqualToString:@"accessToken"]) {
                    if (expectedToken == nil) {
                        expectedToken = [[NSMutableString stringWithString:change[NSKeyValueChangeNewKey]] retain];
                    } else {
                        STAssertTrue([expectedToken isEqualToString:change[NSKeyValueChangeNewKey]], @"accessToken did not match token provided from accessTokenData");
                    }
                } else if ([keyPath isEqualToString:@"accessTokenData"]) {
                    if (expectedToken == nil) {
                        expectedToken = [[NSMutableString stringWithString:((FBAccessTokenData *)change[NSKeyValueChangeNewKey]).accessToken] retain];
                    } else {
                        STAssertTrue([expectedToken isEqualToString:((FBAccessTokenData *)change[NSKeyValueChangeNewKey]).accessToken], @"accessTokenData %@ did not match token provided from accessToken %@", change[NSKeyValueChangeNewKey], expectedToken);
                    }
                }
                break;
            case 1:
                if ([keyPath isEqualToString:@"accessToken"]) {
                    STAssertTrue([expectedToken isEqualToString:change[NSKeyValueChangeNewKey]], @"token changed after reauth");
                } else if ([keyPath isEqualToString:@"state"]) {
                    STAssertEqualObjects([NSNumber numberWithInt:FBSessionStateOpenTokenExtended], change[NSKeyValueChangeNewKey], @"unexpected state");
                }
                break;
            case 2:
                if ([keyPath isEqualToString:@"state"]) {
                    STAssertEqualObjects([NSNumber numberWithInt:FBSessionStateClosed], change[NSKeyValueChangeNewKey], @"expected state to be closed");
                } else if ([keyPath isEqualToString:@"isOpen"]) {
                    STAssertEqualObjects([NSNumber numberWithBool:NO], change[NSKeyValueChangeNewKey], @"expected state to be closed");
                } else {
                    STAssertEqualObjects([NSNull null], change[NSKeyValueChangeNewKey], @"expected null for %@", keyPath);
                }
                break;
        }
    }];

    [target addObserver:kvoHelper forKeyPath:@"isOpen" options:NSKeyValueObservingOptionNew context:nil];
    [target addObserver:kvoHelper forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [target addObserver:kvoHelper forKeyPath:@"accessTokenData" options:NSKeyValueObservingOptionNew context:nil];
    [target addObserver:kvoHelper forKeyPath:@"accessToken" options:NSKeyValueObservingOptionNew context:nil];
    [target addObserver:kvoHelper forKeyPath:@"expirationDate" options:NSKeyValueObservingOptionNew context:nil];

    // Open the session and verify kvo
    [target openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [blocker signal];
    }];
    [blocker wait];
    STAssertTrue(target.isOpen, @"Session should be open, and is not");
    STAssertTrue([expectedKvoValuesForOpening count] == 0, @"There were still expected KVO events that did not occur: %@", expectedKvoValuesForOpening);

    // Now do a reauth and verify kvo
    expectedState = 1;
    [target requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_action"] defaultAudience:FBSessionDefaultAudienceOnlyMe completionHandler:^(FBSession *session, NSError *error) {
        STAssertNil(error, @"unexpected error for new permissions:%@", error);
        [blocker signal];
    }];
    [blocker wait];
    STAssertTrue([expectedKvoValuesForNewPermissions count] == 0, @"There were still expected KVO events that did not occur: %@", expectedKvoValuesForNewPermissions);

    // Now we close the session and verify the kvo again.
    expectedState = 2;
    [target close];
    STAssertTrue([expectedKvoValuesForClosing count] == 0, @"There were still expected KVO events that did not occur: %@", expectedKvoValuesForClosing);

    [target removeObserver:kvoHelper forKeyPath:@"state"];
    [target removeObserver:kvoHelper forKeyPath:@"isOpen"];
    [target removeObserver:kvoHelper forKeyPath:@"expirationDate"];
    [target removeObserver:kvoHelper forKeyPath:@"accessToken"];
    [target removeObserver:kvoHelper forKeyPath:@"accessTokenData"];

    [expectedToken release];
    [target release];
    [expectedKvoValuesForClosing release];
    [expectedKvoValuesForNewPermissions release];
    [expectedKvoValuesForOpening release];
}

@end

#endif
