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
#import "FBTestBlocker.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBSettings.h"
#import "FBError.h"
#import "FBUtility.h"
#import <OCMock/OCMock.h>
#include <pthread.h>

static NSMutableDictionary *mapTestCasesToSessions;
// Concurrency not an issue today, but guard our static global in any case.
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

#pragma mark Private interface

@interface FBIntegrationTests () {
    id _mockFBUtility;
}

- (void)issueFriendRequestInSession:(FBTestSession *)session toFriend:(NSString *)userID;

@end

#pragma mark -

@implementation FBIntegrationTests
{
    FBTestSession *_defaultTestSession;
}

#pragma mark Instance-level lifecycle

- (void)dealloc
{
    [_defaultTestSession release];
    [super dealloc];
}

- (void)setUp
{
    [super setUp];

    pthread_mutex_lock(&mutex);

    if (!mapTestCasesToSessions) {
        mapTestCasesToSessions = [[NSMutableDictionary alloc] init];
    }
    [mapTestCasesToSessions setObject:[[NSMutableArray alloc] init]
                               forKey:[NSValue valueWithNonretainedObject:self]];

    pthread_mutex_unlock(&mutex);

    _mockFBUtility = [[OCMockObject mockForClass:[FBUtility class]] retain];
    [[[_mockFBUtility stub] andReturn:nil] advertiserID]; //stub advertiserID since that often hangs.
}

- (void)tearDown
{
    pthread_mutex_lock(&mutex);

    NSMutableArray *sessions = [mapTestCasesToSessions objectForKey:[NSValue valueWithNonretainedObject:self]];
    [mapTestCasesToSessions removeObjectForKey:[NSValue valueWithNonretainedObject:self]];

    pthread_mutex_unlock(&mutex);

    for (FBSession *session in sessions) {
        [session close];
    }
    [sessions release];

    [_mockFBUtility release];
    _mockFBUtility = nil;

    [super tearDown];
}

#pragma mark -
#pragma mark FBTestSession creation helpers

- (NSArray *)permissionsForDefaultTestSession
{
    return nil;
}

- (FBTestSession *)defaultTestSession
{
    if (!_defaultTestSession) {
        _defaultTestSession = [self getSessionWithSharedUserWithPermissions:[self permissionsForDefaultTestSession]];
    }
    return _defaultTestSession;
}

- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray *)permissions
{
    return [self getSessionWithSharedUserWithPermissions:permissions uniqueUserTag:nil];
}

- (FBTestSession *)getSessionWithSharedUserWithPermissions:(NSArray *)permissions
                                             uniqueUserTag:(NSString *)uniqueUserTag
{
    FBTestSession *session = [FBTestSession sessionWithSharedUserWithPermissions:permissions uniqueUserTag:uniqueUserTag];

    // Need to remember all the sessions for this class.
    pthread_mutex_lock(&mutex);

    NSMutableArray *sessions = [mapTestCasesToSessions objectForKey:[NSValue valueWithNonretainedObject:self]];
    [sessions addObject:session];

    pthread_mutex_unlock(&mutex);

    return [self loginSession:session];
}

#pragma mark -
#pragma mark Miscellaneous helpers

- (FBTestSession *)loginSession:(FBTestSession *)session
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];

    FBSessionStateHandler handler = ^(FBSession *session,
                                      FBSessionState status,
                                      NSError *error) {
        STAssertTrue(!error, @"!error");

        [blocker signal];
    };

    [session openWithCompletionHandler:handler];

    BOOL success = [blocker waitWithTimeout:60];
    STAssertTrue(success, @"blocker timed out");
    STAssertTrue(session.isOpen, @"session.isOpen");

    return session;
}

- (void)issueFriendRequestInSession:(FBTestSession *)session toFriend:(NSString *)userID
{
    STAssertNotNil(userID, @"missing userID");
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
         STAssertTrue(expected, @"unexpected result");
         [blocker signal];
     }];

    [blocker wait];
}

- (void)makeTestUserInSession:(FBTestSession *)session1 friendsWithTestUserInSession:(FBTestSession *)session2
{
    [self issueFriendRequestInSession:session1 toFriend:session2.testUserID];
    [self issueFriendRequestInSession:session2 toFriend:session1.testUserID];
}

- (void)validateGraphObject:(id<FBGraphObject>)graphObject hasProperties:(NSArray *)propertyNames
{
    for (NSString *propertyName in propertyNames) {
        STAssertNotNil([graphObject objectForKey:propertyName],
                       [NSString stringWithFormat:@"missing property '%@'", propertyName]);
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
         STAssertTrue(!error, @"!error");
         STAssertTrue([idString isEqualToString:[result objectForKey:@"id"]], @"wrong id");

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
         STAssertTrue(!error, @"!error");
         if (!error) {
             NSString *newObjectId = [result objectForKey:@"id"];
             [self validateGraphObjectWithId:newObjectId
                               hasProperties:propertyNames
                                 withSession:session
                                     blocker:blocker];
         }
         [blocker signal];
     }];

    STAssertTrue([blocker waitWithTimeout:15], @"blocker timed out");
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
     ^(FBRequestConnection *connection, id result, NSError *error) {
         STAssertTrue(!error, @"got unexpected error");
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
     ^(FBRequestConnection *connection, id result, NSError *error) {
         STAssertTrue(!error, @"got unexpected error");
         STAssertNotNil(result, @"didn't get expected result");
         createdObject = [result retain];
         [blocker signal];
     }];

    [connection start];
    [blocker wait];

    [postRequest release];
    [connection release];
    [blocker release];

    return [createdObject autorelease];
}

size_t getPixels(void *info, void *buffer, size_t count) {
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

#pragma mark -
#pragma mark Handlers

- (FBRequestHandler)handlerExpectingSuccessSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertTrue(!error, @"got unexpected error");
        STAssertNotNil(result, @"didn't get expected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

- (FBRequestHandler)handlerExpectingFailureSignaling:(FBTestBlocker *)blocker {
    FBRequestHandler handler =
    ^(FBRequestConnection *connection, id result, NSError *error) {
        STAssertNotNil(error, @"didn't get expected error");
        STAssertTrue(!result, @"got unexpected result");
        [blocker signal];
    };
    return [[handler copy] autorelease];
}

#pragma mark -

@end
