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

#import <OCMock/OCMock.h>

#import "FBAppBridge.h"
#import "FBAppBridgeScheme.h"
#import "FBAppCall+Internal.h"
#import "FBDialogsData+Internal.h"
#import "FBError.h"
#import "FBInternalSettings.h"
#import "FBTestBlocker.h"
#import "FBTests.h"
#import "FBUtility.h"

static NSString *const kTestAppID = @"123456789";
static NSString *const kTestURLScheme = @"fb123456789";
static NSString *const kTestAppName = @"Awesome App";
static NSString *const kTestURLSchemeSuffix = @"mysuffix";
static NSString *const kTestNonFacebookBundleIdentifier = @"com.notfacebook.hello";
static NSString *const kTestFacebookBundleIdentifier = @"com.facebook.hello";
static FBAppBridgeScheme *testBridgeScheme = nil;

// If we create an FBDialogsData, we'll use this data.
static NSString *const kTestDialogMethod = @"some_dialog";

static NSString *const kNonAppBridgeAppCallURL = @"fb123456789://link?meal=Chicken&fb_applink_args=%7B%22version%22%3A2%2C%22bridge_args%22%3A%7B%22method%22%3A%22applink%22%7D%2C%22method_args%22%3A%7B%22ref%22%3A%22Tiramisu%22%7D%7D&fb_click_time_utc=123";

@interface FBAppBridge (FBAppBridgeTests)

@property (nonatomic, retain) NSMutableDictionary *pendingAppCalls;
@property (nonatomic, retain) NSMutableDictionary *callbacks;

+ (NSString *)symmetricKeyAndForceRefresh:(BOOL)forceRefresh;

- (void)performDialogAppCall:(FBAppCall *)appCall
                bridgeScheme:(FBAppBridgeScheme *)bridgeScheme
                     session:(FBSession *)session
     useSafariViewController:(BOOL)useSafariViewController
           completionHandler:(FBAppCallHandler)handler;

@end

@interface FBAppBridgeTests : FBTests
@end

@implementation FBAppBridgeTests
{
    id _mockApplication;
    // This one is just here to keep UIApplication class methods mocked without a circular reference.
    id _anotherMockApplication;
    id _mockFBSettings;
}

#pragma mark Helpers

+ (void)setUp {
    if (testBridgeScheme == nil) {
        // For these unit tests, the actual scheme isn't important (since we mock/expect).
        testBridgeScheme = [[FBAppBridgeScheme alloc] init];
    }
}
- (void)setUp {
    [super setUp];
    // FBAppBridge relies on UIApplication for handling URLs; mock it and return
    // the mock from [UIApplication sharedApplication]. This little dance is necessary to avoid
    // a circular reference that keeps the class method from being unmocked.
    _mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    _anotherMockApplication = [OCMockObject mockForClass:[UIApplication class]];
    [[[_anotherMockApplication stub] andReturn:_mockApplication] sharedApplication];

    // FBAppBridge assumes it can get an app ID.
    _mockFBSettings = [OCMockObject mockForClass:[FBSettings class]];
    [[[_mockFBSettings stub] andReturn:kTestAppID] defaultAppID];
    [[[_mockFBSettings stub] andReturn:kTestAppName] defaultDisplayName];
    
    // Pretend that all URL schemes are registered or [FBAppCall init] will fail.
    BOOL yes = YES;

    [[[self.mockFBUtility stub] andReturnValue:OCMOCK_VALUE(yes)]
        isRegisteredURLScheme:kTestURLScheme];
    [[_mockApplication stub] keyWindow];
}

- (void)tearDown {
    // Deallocing the mock will also revert the class method mocking.
    _mockApplication = nil;
    _anotherMockApplication = nil;
    _mockFBSettings = nil;
    [super tearDown];
}

- (FBAppCall *)newAppCall:(BOOL)withDialogsData {
    return [self newAppCall:withDialogsData arguments:nil];
}

- (FBAppCall *)newAppCall:(BOOL)withDialogsData arguments:(NSDictionary *)arguments {
    FBAppCall *appCall = [[[FBAppCall alloc] init] autorelease];
    if (withDialogsData) {
        appCall.dialogData = [[[FBDialogsData alloc] initWithMethod:kTestDialogMethod
                                                         arguments:arguments] autorelease];
    }
    return appCall;
}

// Helpers to construct incoming URLs for testing handleOpenURL, etc.
- (NSURL *)newAppBridgeURL {
    return [self newAppBridgeURL:nil version:nil];
}

- (NSURL *)newAppBridgeURL:(NSString *)callId version:(NSString *)version {
    return [self newAppBridgeURL:callId version:version methodArgs:nil clientState:nil];
}

- (NSURL *)newAppBridgeURL:(NSString *)callId
                   version:(NSString *)version
                methodArgs:(NSDictionary *)methodArgs
               clientState:(NSDictionary *)clientState {
    NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *bridgeArgs = [[[NSMutableDictionary alloc] init] autorelease];

    if (callId != nil) {
        bridgeArgs[@"action_id"] = callId;
    }
    if (clientState.count > 0) {
        bridgeArgs[@"client_state"] = [FBUtility simpleJSONEncode:clientState];
    }
    if (bridgeArgs.count > 0) {
        params[@"bridge_args"] = [FBUtility simpleJSONEncode:bridgeArgs];
    }
    if (methodArgs.count > 0) {
        params[@"method_args"] = [FBUtility simpleJSONEncode:methodArgs];
    }
    if (version != nil) {
        params[@"version"] = version;
    }

    NSString *query = @"";
    if (params.count > 0) {
        query = [NSString stringWithFormat:@"?%@", [FBUtility stringBySerializingQueryParameters:params]];
    }

    NSString *urlString = [NSString stringWithFormat:@"%@://bridge/%@%@",
                           kTestURLScheme, kTestDialogMethod, query];
    return [NSURL URLWithString:urlString];
}


#pragma mark Class method tests

- (void)testSharedInstanceIsSingleton {
    XCTAssertEqual([FBAppBridge sharedInstance], [FBAppBridge sharedInstance]);
}

#pragma mark dispatchDialogAppCall/performDialogAppCall tests

- (void)testDispatchCallsPerformWithSameArgs {
    // Most of the rest of our tests just call performDialogAppCall:... on the test
    // thread to avoid threading complexity. But that shortcut assumes that dispatchDialogAppCall:...
    // just dispatches performDialogAppCall: on the main thread. So this test asserts that
    // the rest of the tests can make that simplifying assumption.
    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    id mockAppBridge = [OCMockObject partialMockForObject:appBridge];

    FBAppCall *appCall = [self newAppCall:NO];
    FBSession *session = [[[FBSession alloc] init] autorelease];
    id handler = ^(FBAppCall *call) {
    };

    [[mockAppBridge expect] performDialogAppCall:appCall
                                    bridgeScheme:testBridgeScheme
                                         session:session
                         useSafariViewController:NO
                               completionHandler:handler];
    
    [mockAppBridge dispatchDialogAppCall:appCall
                            bridgeScheme:testBridgeScheme
                                 session:session
                 useSafariViewController:NO
                       completionHandler:handler];

    [self waitForMainQueueToFinish];
    [mockAppBridge verify];

}

- (void)testNoDialogDataResultsInNoCall {
    [[_mockApplication reject] openURL:OCMOCK_ANY];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];

    FBAppCall *appCall = [self newAppCall:NO];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:nil];

    [_mockApplication verify];
}

- (void)testAppIDIncludedInGeneratedURL {
    FBAppCall *appCall = [self newAppCall:YES];

    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[_mockApplication expect] openURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [[FBUtility dictionaryByParsingURLQueryPart:((NSURL *)obj).query][@"app_id"] isEqualToString:kTestAppID];

    }]];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:nil];
    
    [_mockApplication verify];
}

- (void)testInitFailsIfMissingAppID {
    _mockFBSettings = [OCMockObject mockForClass:[FBSettings class]];
    [[[_mockFBSettings stub] andReturn:nil] defaultAppID];

    XCTAssertThrowsSpecificNamed(
                                [[[FBAppBridge alloc] init] autorelease],
                                NSException,
                                FBInvalidOperationException,
                                @"expected exception");

    [_mockApplication verify];
}

- (void)testAppMetadataIncludedInGeneratedURL {
    FBAppCall *appCall = [self newAppCall:YES];

    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[_mockApplication expect] openURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dict = [FBUtility simpleJSONDecode:
                              [FBUtility dictionaryByParsingURLQueryPart:
                               ((NSURL *)obj).query][@"bridge_args"]];
        return ([dict[@"app_name"] isEqualToString:kTestAppName] &&
                [dict[@"action_id"] isEqualToString:appCall.ID]);
    }]];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:nil];

    [_mockApplication verify];
}

// TODO add a test for app icon being serialized correctly

- (void)testClientStateIncludedInGeneratedURL {
    FBAppCall *appCall = [self newAppCall:YES];

    NSDictionary *clientState = @{@"foo": @"bar", @"hello": @"world"};
    appCall.dialogData.clientState = clientState;
    
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[_mockApplication expect] openURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dict = [FBUtility simpleJSONDecode:
                              [FBUtility dictionaryByParsingURLQueryPart:
                               ((NSURL *)obj).query][@"bridge_args"]];
        return [dict[@"client_state"] isEqualToString:[FBUtility simpleJSONEncode:clientState]];
    }]];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:nil];
    
    [_mockApplication verify];
}

- (void)testURLSchemeSuffixIncludedInGeneratedURL {
    FBAppCall *appCall = [self newAppCall:YES];

    FBSession *session = [[[FBSession alloc] initWithAppID:kTestAppID
                                               permissions:nil
                                           urlSchemeSuffix:kTestURLSchemeSuffix
                                        tokenCacheStrategy:nil] autorelease];
    
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[_mockApplication expect] openURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [[FBUtility dictionaryByParsingURLQueryPart:((NSURL *)obj).query][@"scheme_suffix"] isEqualToString:kTestURLSchemeSuffix];
    }]];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:session
            useSafariViewController:NO
                  completionHandler:nil];
    
    [_mockApplication verify];
}

- (void)testMethodArgumentsIncludedInGeneratedURL {
    NSDictionary *arguments = @{@"foo": @"bar", @"hello": @"world"};
    FBAppCall *appCall = [self newAppCall:YES arguments:arguments];


    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[_mockApplication expect] openURL:[OCMArg checkWithBlock:^BOOL(id obj) {
        return ([FBUtility dictionaryByParsingURLQueryPart:((NSURL *)obj).query][@"method_args"]!=nil);
    }]];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:nil];

    [_mockApplication verify];
}

- (void)testAppCallIsTrackedOnSuccessfulOpen {
    BOOL yes = YES;
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[[_mockApplication expect] andReturnValue:OCMOCK_VALUE(yes)] openURL:OCMOCK_ANY];

    FBAppCall *appCall = [self newAppCall:YES];
    id handler = ^(FBAppCall *call) {
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:handler];

    [_mockApplication verify];

    XCTAssertTrue([appBridge.pendingAppCalls[appCall.ID] isEqual:appCall]);
    XCTAssertNotNil(appBridge.callbacks[appCall.ID]);
}

- (void)testAppCallIsNotTrackedOnFailedOpen {
    BOOL no = NO;
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[[_mockApplication expect] andReturnValue:OCMOCK_VALUE(no)] openURL:OCMOCK_ANY];

    FBAppCall *appCall = [self newAppCall:YES];
    id handler = ^(FBAppCall *call) {
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:handler];

    [_mockApplication verify];

    XCTAssertNil(appBridge.pendingAppCalls[appCall.ID]);
    XCTAssertNil(appBridge.callbacks[appCall.ID]);
}

- (void)testHandlerCalledWithErrorOnFailedOpen {
    BOOL no = NO;
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[[_mockApplication expect] andReturnValue:OCMOCK_VALUE(no)] openURL:OCMOCK_ANY];

    FBAppCall *appCall = [self newAppCall:YES];
    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call.error);
        XCTAssertTrue([FacebookSDKDomain isEqualToString:call.error.domain]);
        XCTAssertEqual(FBErrorDialog, call.error.code);
        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:handler];

    [_mockApplication verify];

    XCTAssertTrue(handlerCalled);
}

#pragma mark handleDidBecomeActive tests

- (void)testPendingCallIsCanceledOnDidBecomeActive {
    BOOL yes = YES;
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[[_mockApplication expect] andReturnValue:OCMOCK_VALUE(yes)] openURL:OCMOCK_ANY];

    FBAppCall *appCall = [self newAppCall:YES];
    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call.error);
        XCTAssertTrue([FacebookSDKDomain isEqualToString:call.error.domain]);
        XCTAssertEqual(FBErrorAppActivatedWhilePendingAppCall, call.error.code);
        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:handler];

    [appBridge handleDidBecomeActive];
    
    [_mockApplication verify];

    XCTAssertTrue(handlerCalled);
}

#pragma mark handleOpenURL tests

- (void)testWrongURLSchemeReturnsNoWithoutCallingFallbackHandler {
    NSURL *url = [NSURL URLWithString:@"nope://bridge/"];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:nil
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertFalse(result);
    XCTAssertFalse(handlerCalled);
}

- (void)testWrongURLHostReturnsNoWithoutCallingFallbackHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/nope/", kTestURLScheme]];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:nil
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertFalse(result);
    XCTAssertFalse(handlerCalled);
}

- (void)testNonAppBridgeURLWithoutFallbackHandlerReturnsNo {
    NSURL *url = [NSURL URLWithString:kNonAppBridgeAppCallURL];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:nil
                                   session:nil
                           fallbackHandler:nil];

    XCTAssertFalse(result);
}

- (void)testNonAppBridgeURLCallsFallbackHandlerAndReturnsYes {
    NSURL *url = [NSURL URLWithString:kNonAppBridgeAppCallURL];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call);
        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:nil
                                   session:nil
                           fallbackHandler:handler];
    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
}

- (void)testNonFacebookSourceApplicationFails {
    NSURL *url = [self newAppBridgeURL];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call.error);
        XCTAssertTrue([FacebookSDKDomain isEqualToString:call.error.domain]);
        XCTAssertEqual(FBErrorUntrustedURL, call.error.code);

        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestNonFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
}

- (void)testNonFacebookSourceApplicationChangesSymmetricKey {
    NSURL *url = [self newAppBridgeURL];

    NSString *oldKey = [FBAppBridge symmetricKeyAndForceRefresh:NO];

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestNonFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:nil];

    XCTAssertTrue(result);

    NSString *newKey = [FBAppBridge symmetricKeyAndForceRefresh:NO];
    XCTAssertFalse([oldKey isEqualToString:newKey]);
}

- (void)testURLWithoutCallIDFails {
    NSURL *url = [self newAppBridgeURL:nil version:@"1"];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call.error);
        XCTAssertTrue([FacebookSDKDomain isEqualToString:call.error.domain]);
        XCTAssertEqual(FBErrorMalformedURL, call.error.code);

        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
}

- (void)testURLWithoutVersionFails {
    NSURL *url = [self newAppBridgeURL:[FBUtility newUUIDString] version:nil];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call.error);
        XCTAssertTrue([FacebookSDKDomain isEqualToString:call.error.domain]);
        XCTAssertEqual(FBErrorMalformedURL, call.error.code);

        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
}

- (void)testURLWithUntrackedCallIDCallsFallbackHandler {
    NSString *callID = [FBUtility newUUIDString];
    NSDictionary *methodArgs = @{@"foo": @"bar"};
    NSDictionary *clientState = @{@"hello": @"world"};
    NSURL *url = [self newAppBridgeURL:callID version:@"1" methodArgs:methodArgs clientState:clientState];

    BOOL __block handlerCalled = NO;
    id handler = ^(FBAppCall *call) {
        XCTAssertNotNil(call);
        XCTAssertNil(call.error);
        XCTAssertTrue([call.ID isEqualToString:callID]);

        XCTAssertTrue([kTestDialogMethod isEqualToString:call.dialogData.method]);
        XCTAssertEqualObjects(methodArgs, call.dialogData.arguments);
        XCTAssertEqualObjects(clientState, call.dialogData.clientState);

        handlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:handler];

    XCTAssertTrue(result);
    XCTAssertTrue(handlerCalled);
}

- (void)testURLWithTrackedCallIDCallsHandler {
    NSDictionary *methodArgs = @{@"foo": @"bar"};
    NSDictionary *clientState = @{@"hello": @"world"};

    BOOL yes = YES;
    [[_mockApplication expect] canOpenURL:[NSURL URLWithString:@"fbapi://"]];
    [[[_mockApplication expect] andReturnValue:OCMOCK_VALUE(yes)] openURL:OCMOCK_ANY];

    FBAppCall *appCall = [self newAppCall:YES arguments:methodArgs];
    appCall.dialogData.clientState = clientState;

    BOOL __block completionHandlerCalled = NO;
    id completionHandler = ^(FBAppCall *call) {
        XCTAssertNotNil(call);
        XCTAssertNil(call.error);
        XCTAssertTrue([call.ID isEqualToString:appCall.ID]);

        XCTAssertTrue([kTestDialogMethod isEqualToString:call.dialogData.method]);
        XCTAssertEqualObjects(methodArgs, call.dialogData.arguments);
        XCTAssertEqualObjects(clientState, call.dialogData.clientState);

        completionHandlerCalled = YES;
    };

    FBAppBridge *appBridge = [[[FBAppBridge alloc] init] autorelease];
    [appBridge performDialogAppCall:appCall
                       bridgeScheme:testBridgeScheme
                            session:nil
            useSafariViewController:NO
                  completionHandler:completionHandler];

    [_mockApplication verify];

    XCTAssertEqualObjects(appCall, appBridge.pendingAppCalls[appCall.ID]);
    XCTAssertNotNil(appBridge.callbacks[appCall.ID]);

    // We should get original method args, client state, etc., even if they aren't in the URL.
    NSURL *url = [self newAppBridgeURL:appCall.ID version:@"1" methodArgs:nil clientState:nil];

    BOOL __block fallbackHandlerCalled = NO;
    id fallbackHandler = ^(FBAppCall *call) {
        fallbackHandlerCalled = YES;
    };

    BOOL result = [appBridge handleOpenURL:url
                         sourceApplication:kTestFacebookBundleIdentifier
                                   session:nil
                           fallbackHandler:fallbackHandler];

    XCTAssertTrue(result);
    XCTAssertTrue(completionHandlerCalled);
    XCTAssertFalse(fallbackHandlerCalled);

    XCTAssertNil(appBridge.pendingAppCalls[appCall.ID]);
    XCTAssertNil(appBridge.callbacks[appCall.ID]);
}

#pragma mark Encryption/decryption tests

// TODO

#pragma mark Pasteboard tests

// TODO

@end
