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

#import "FBIntegrationTests.h"

#import <pthread.h>

#import <OCMock/OCMock.h>

#import "FBError.h"
#import "FBInternalSettings.h"
#import "FBRequest.h"
#import "FBRequestConnection.h"
#import "FBTestBlocker.h"
#import "FBTestUserSession.h"
#import "FBTestUsersManager.h"
#import "FBUtility.h"

static NSString *const FBPLISTTestAppIDKey = @"IOS_SDK_TEST_APP_ID";
static NSString *const FBPLISTTestAppSecretKey = @"IOS_SDK_TEST_APP_SECRET";
static NSString *const FBPLISTTestAppClientTokenKey = @"IOS_SDK_TEST_CLIENT_TOKEN";

static FBTestUsersManager *testAccountsManager;
static NSString *gAppId;
static NSString *gAppSecret;
static NSString *gAppClientToken;

@implementation FBIntegrationTests
{
    FBTestUserSession *_defaultTestSession;
    id _mockFBUtility;
    id _mockNSBundle;
}

#pragma mark Instance-level lifecycle

- (void)dealloc
{
    [_defaultTestSession release];
    [super dealloc];
}

+ (void)setUp {
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    gAppId = [environment objectForKey:FBPLISTTestAppIDKey];
    gAppSecret = [environment objectForKey:FBPLISTTestAppSecretKey];
    gAppClientToken= [environment objectForKey:FBPLISTTestAppClientTokenKey];
    if (gAppId.length == 0 || gAppSecret.length == 0 || gAppClientToken.length == 0) {
        [[NSException exceptionWithName:FBInvalidOperationException
                                 reason:
          @"Integration Tests Cannot Be Run."
          @"Missing App ID or App Secret, or Client Token in Build Settings."
          @" You can set this in an xcconfig file containing your unit-testing Facebook"
          @" Application's ID and Secret in this format:\n"
          @"\tIOS_SDK_TEST_APP_ID = // your app ID, e.g.: 1234567890\n"
          @"\tIOS_SDK_TEST_APP_SECRET = // your app secret, e.g.: 1234567890abcdef\n"
          @"\tIOS_SDK_TEST_CLIENT_TOKEN = // your app client token, e.g.: 1234567890abcdef\n"
          @"Do NOT release your app secret in your app"
          @"To create a Facebook AppID, visit https://developers.facebook.com/apps"
                               userInfo:nil]
         raise];
    }
    testAccountsManager = [FBTestUsersManager sharedInstanceForAppId:gAppId appSecret:gAppSecret];
}
- (void)setUp
{
    [super setUp];
    self.continueAfterFailure = NO;

    _mockFBUtility = [[OCMockObject mockForClass:[FBUtility class]] retain];
    [[[_mockFBUtility stub] andReturn:nil] advertiserID]; //stub advertiserID since that often hangs.

    _mockNSBundle = [[OCMockObject partialMockForObject:[NSBundle mainBundle]] retain];
    [[[_mockNSBundle stub] andReturn:[[NSUUID UUID] UUIDString]] bundleIdentifier];
}

- (void)tearDown
{
    [_mockFBUtility release];
    _mockFBUtility = nil;

    [_mockNSBundle release];
    _mockNSBundle = nil;

    [super tearDown];
}

#pragma mark -
#pragma mark test session creation helpers

- (NSArray *)permissionsForDefaultTestSession
{
    return @[];
}

- (FBTestUserSession *)defaultTestSession
{
    if (!_defaultTestSession) {
        _defaultTestSession = (FBTestUserSession *)[self loginSession:[self getTestSessionWithPermissions:[self permissionsForDefaultTestSession]]];
    }
    return _defaultTestSession;
}

- (FBTestUserSession *)getTestSessionWithPermissions:(NSArray *)permissions
{
    return [self getTestSessionsWithPermissions:permissions count:1][0];
}

- (NSArray *)getTestSessionsWithPermissions:(NSArray *)permissions count:(NSUInteger)count {
    FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
    NSMutableArray *arrayOfPermissionsArrays = [NSMutableArray array];
    // wrap the permissions into another array and copy in case caller mutates theirs.
    while (count > 0) {
        [arrayOfPermissionsArrays addObject:(permissions ? [[permissions copy] autorelease] : @[] )];
        count--;
    }
    __block NSMutableArray *testSessionsArray = [NSMutableArray array];
    [testAccountsManager requestTestAccountTokensWithArraysOfPermissions:arrayOfPermissionsArrays
                                                        createIfNotFound:YES
                                                       completionHandler:^(NSArray *tokens, NSError *error) {
                                                           XCTAssertNil(error, @"failed to get test users :%@", error);
                                                           [tokens enumerateObjectsUsingBlock:^(FBAccessTokenData *obj, NSUInteger idx, BOOL *stop) {
                                                               [testSessionsArray addObject:[FBTestUserSession sessionWithAccessTokenData:obj]];
                                                           }];
                                                           [blocker signal];
                                                       }];
    XCTAssertTrue([blocker waitWithTimeout:30], @"timed out trying to fetch test user");
    [blocker release];
    return testSessionsArray;
}

#pragma mark -
#pragma mark Miscellaneous helpers

- (NSString *)testAppId{
    return gAppId;
}

- (NSString *)testAppClientToken {
    return gAppClientToken;
}

- (NSString *)testAppSecret {
    return gAppSecret;
}

- (FBSession *)loginSession:(FBSession *)session
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];

    FBSessionStateHandler handler = ^(FBSession *innerSession,
                                      FBSessionState status,
                                      NSError *error) {
        XCTAssertTrue(!error, @"!error");

        [blocker signal];
    };

    [session openWithCompletionHandler:handler];

    BOOL success = [blocker waitWithTimeout:60];
    XCTAssertTrue(success, @"blocker timed out");
    XCTAssertTrue(session.isOpen, @"session.isOpen");

    return session;
}

- (void)issueFriendRequestInSession:(FBSession *)session toFriend:(NSString *)userID
{
    XCTAssertNotNil(userID, @"missing userID");
    NSString *graphPath = [NSString stringWithFormat:@"me/friends/%@", userID];

    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];

    FBRequest *request = [[[FBRequest alloc] initForPostWithSession:session
                                                          graphPath:graphPath
                                                        graphObject:nil]
                          autorelease];

    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         BOOL expected = (result && !error);
         if (error) {
             id code = [[error userInfo] objectForKey:FBErrorHTTPStatusCodeKey];
             // If test users are already friends, we will get a 400.
             expected = [code integerValue] == 400;
         }
         XCTAssertTrue(expected, @"unexpected result");
         [blocker signal];
     }];

    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");
}

- (void)makeTestUserInSession:(FBSession *)session1 friendsWithTestUserInSession:(FBSession *)session2
{
    XCTAssertTrue(session1.accessTokenData.userID.length > 0, @"missing user id for session 1");
    XCTAssertTrue(session2.accessTokenData.userID.length > 0, @"missing user id for session 2");

    [self issueFriendRequestInSession:session1 toFriend:session2.accessTokenData.userID];
    [self issueFriendRequestInSession:session2 toFriend:session1.accessTokenData.userID];
}

- (void)validateGraphObject:(id<FBGraphObject>)graphObject hasProperties:(NSArray *)propertyNames
{
    for (NSString *propertyName in propertyNames) {
        XCTAssertNotNil([graphObject objectForKey:propertyName],
                        @"missing property '%@'",
                        propertyName);
    }
}

- (void)validateGraphObjectWithId:(NSString *)idString
                    hasProperties:(NSArray *)propertyNames
                      withSession:(FBSession *)session
                          blocker:(FBTestBlocker *)blocker {
    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                   graphPath:idString]
                          autorelease];

    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         XCTAssertTrue(!error, @"!error");
         XCTAssertTrue([idString isEqualToString:[result objectForKey:@"id"]], @"wrong id");

         [self validateGraphObject:result hasProperties:propertyNames];

         [blocker signal];
     }];
}

- (void)postAndValidateWithSession:(FBSession *)session
                         graphPath:(NSString *)graphPath
                       graphObject:(id)graphObject
                     hasProperties:(NSArray *)propertyNames {
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:2];

    FBRequest *request = [[[FBRequest alloc] initForPostWithSession:session
                                                          graphPath:graphPath
                                                        graphObject:graphObject]
                          autorelease];

    [request startWithCompletionHandler:
     ^(FBRequestConnection *connection, id result, NSError *error) {
         XCTAssertTrue(!error, @"!error :%@", error);
         if (!error) {
             NSString *newObjectId = [result objectForKey:@"id"];
             [self validateGraphObjectWithId:newObjectId
                               hasProperties:propertyNames
                                 withSession:session
                                     blocker:blocker];
         }
         [blocker signal];
     }];

    XCTAssertTrue([blocker waitWithTimeout:15], @"blocker timed out");
}

// Unit tests failing? Turn on some logging with this helper.
- (void)logRequestsAndConnections
{
    [FBSettings setLoggingBehavior:[NSSet setWithObjects:
                                    FBLoggingBehaviorFBRequests,
                                    FBLoggingBehaviorFBURLConnections,
                                    FBLoggingBehaviorAccessTokens,
                                    nil]];
}

- (id)batchedPostAndGetWithSession:(FBSession *)session
                         graphPath:(NSString *)graphPath
                       graphObject:(id)graphObject {
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    // Create the thing.
    FBRequest *postRequest = [[FBRequest alloc] initForPostWithSession:session
                                                             graphPath:graphPath
                                                           graphObject:graphObject];
    [connection addRequest:postRequest
         completionHandler:
     ^(FBRequestConnection *innerConnection, id result, NSError *error) {
         XCTAssertTrue(!error, @"got unexpected error");
     }
            batchEntryName:@"postRequest"];

    FBRequest *getRequest = [[FBRequest alloc] initWithSession:session
                                                     graphPath:@"{result=postRequest:$.id}"
                                                    parameters:nil
                                                    HTTPMethod:nil];
    __block id createdObject = nil;
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [connection addRequest:getRequest
         completionHandler:
     ^(FBRequestConnection *innerConnection, id result, NSError *error) {
         XCTAssertTrue(!error, @"got unexpected error");
         XCTAssertNotNil(result, @"didn't get expected result");
         createdObject = [result retain];
         [blocker signal];
     }];

    [connection start];
    XCTAssertTrue([blocker waitWithTimeout:30], @"blocker timed out");

    [postRequest release];
    [connection release];
    [blocker release];

    return [createdObject autorelease];
}

static size_t getPixels(void *info, void *buffer, size_t count) {
    char *c = buffer;
    for (int i = 0; i < count; ++i) {
        *c = arc4random() % 256;
    }
    return count;
}

- (UIImage *)createSquareTestImage:(int)size
{
    CGDataProviderSequentialCallbacks providerCallbacks;
    memset(&providerCallbacks, 0, sizeof(providerCallbacks));
    providerCallbacks.getBytes = getPixels;

    CGDataProviderRef provider = CGDataProviderCreateSequential(NULL, &providerCallbacks);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

    int width = size;
    int height = size;
    int bitsPerComponent = 8;
    int bitsPerPixel = 8;
    int bytesPerRow = width * (bitsPerPixel/8);

    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       bitsPerComponent,
                                       bitsPerPixel,
                                       bytesPerRow,
                                       colorSpace,
                                       kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:cgImage];

    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage);

    return image;
}

#pragma mark - Handlers

- (FBRequestHandler)handlerExpectingSuccessSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        XCTAssertTrue(!error, @"got unexpected error");
        XCTAssertNotNil(result, @"didn't get expected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

- (FBRequestHandler)handlerExpectingFailureSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        XCTAssertNotNil(error, @"didn't get expected error");
        XCTAssertTrue(!result, @"got unexpected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

@end
