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

#import "FBBatchRequestIntegrationTests.h"
#import "FBTestSession.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBGraphUser.h"

#if defined(FACEBOOKSDK_SKIP_BATCH_REQUEST_TESTS)

#pragma message ("warning: Skipping FBBatchRequestTests")

#else

@implementation FBBatchRequestIntegrationTests

- (void)testBatchingTwoSearches
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.889468, -77.03524);
    FBRequest *request1 = [FBRequest requestForPlacesSearchAtCoordinate:coordinate 
                                                         radiusInMeters:100 
                                                           resultsLimit:5 
                                                             searchText:@"Lincoln Memorial"];
    [request1 setSession:self.defaultTestSession];
    FBRequest *request2 = [FBRequest requestForPlacesSearchAtCoordinate:coordinate 
                                                         radiusInMeters:100 
                                                           resultsLimit:5 
                                                             searchText:@"Washington Monument"];
    [request2 setSession:self.defaultTestSession];

    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:2];

    [connection addRequest:request1 completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
    [connection addRequest:request2 completionHandler:[self handlerExpectingSuccessSignaling:blocker]];
         
    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testDifferentAccessTokens
{
    FBTestSession *session1 = self.defaultTestSession;
    FBTestSession *session2 = [self getSessionWithSharedUserWithPermissions:nil
                                                              uniqueUserTag:kSecondTestUserTag];
    
    FBRequest *request1 = [[[FBRequest alloc] initWithSession:session1
                                                    graphPath:@"me"]
                           autorelease];
    FBRequest *request2 = [[[FBRequest alloc] initWithSession:session2
                                                    graphPath:@"me"]
                           autorelease];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             id<FBGraphUser> user = result;
             STAssertTrue([user.id isEqualToString:self.defaultTestSession.testUserID], @"wrong user");
         }];
    [connection addRequest:request2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             id<FBGraphUser> user = result;
             STAssertTrue([user.id isEqualToString:session2.testUserID], @"wrong user");
             
             [blocker signal];
         }];
    
    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testBatchWithValidSessionAndNoSession
{
    FBRequest *request1 = [[[FBRequest alloc] initWithSession:self.defaultTestSession
                                                    graphPath:@"me"]
                           autorelease];
    FBRequest *request2 = [[[FBRequest alloc] initWithSession:nil
                                                    graphPath:@"zuck"]
                           autorelease];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
         }];
    [connection addRequest:request2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             [blocker signal];
         }];
    
    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testBatchWithNoSessionAndValidSession
{
    FBRequest *request1 = [[[FBRequest alloc] initWithSession:nil
                                                    graphPath:@"zuck"]
                           autorelease];
    FBRequest *request2 = [[[FBRequest alloc] initWithSession:self.defaultTestSession
                                                    graphPath:@"me"]
                           autorelease];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
         }];
    [connection addRequest:request2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             [blocker signal];
         }];
    
    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testBatchWithTwoSessionlessRequestsAndDefaultAppID
{
    // Only use this to get the unit-testing app ID.
    FBTestSession *session = self.defaultTestSession;
    [FBSession setDefaultAppID:session.testAppID];
    
    FBRequest *request1 =[[[FBRequest alloc] initWithSession:nil
                                                   graphPath:@"zuck"]
                          autorelease];
    FBRequest *request2 = [[[FBRequest alloc] initWithSession:nil
                                                    graphPath:@"zuck"]
                           autorelease];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    
    [connection addRequest:request1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
         }];
    [connection addRequest:request2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             [blocker signal];
         }];
    
    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testMixedSuccessAndFailure
{
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];

    const int kNumRequests = 8;
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:kNumRequests];

    for (int i = 0; i < kNumRequests; ++i) {
        BOOL success = (i % 2) == 1;
        FBRequest *request = [[[FBRequest alloc] initWithSession:self.defaultTestSession
                                                       graphPath:success ? @"me" : @"-1"]
                              autorelease];
        [connection addRequest:request 
             completionHandler:success ? 
                [self handlerExpectingSuccessSignaling:blocker] :
                [self handlerExpectingFailureSignaling:blocker]];
    }

    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

- (void)testBatchUploadPhoto
{
    FBTestSession *session = [self getSessionWithSharedUserWithPermissions:[NSArray arrayWithObject:@"user_photos"]];
    
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:4];
    
    const int image1Size = 120;
    const int image2Size = 150;
    
    FBRequest *uploadRequest1 = [FBRequest requestForUploadPhoto:[self createSquareTestImage:image1Size]];
    [uploadRequest1 setSession:session];
    [connection addRequest:uploadRequest1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             [blocker signal];
         }
         batchEntryName:@"uploadRequest1"];

    FBRequest *uploadRequest2 = [FBRequest requestForUploadPhoto:[self createSquareTestImage:image2Size]];
    [uploadRequest2 setSession:session];
    [connection addRequest:uploadRequest2
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             [blocker signal];
         }
         batchEntryName:@"uploadRequest2"];

    FBRequest *getRequest1 = [[FBRequest alloc] initWithSession:session 
                                                      graphPath:@"{result=uploadRequest1:$.id}"
                                                     parameters:nil
                                                     HTTPMethod:nil];
    [connection addRequest:getRequest1 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");
             
             NSDecimalNumber *width = [result objectForKey:@"width"];
             STAssertNotNil(width, @"couldn't get width");
             STAssertTrue(image1Size == (int)[width doubleValue], @"wrong width");
             NSLog(@"%@", width);

             [blocker signal];
         }]; 
    FBRequest *getRequest2 = [[FBRequest alloc] initWithSession:session 
                                                      graphPath:@"{result=uploadRequest2:$.id}"
                                                     parameters:nil
                                                     HTTPMethod:nil];
    [connection addRequest:getRequest2 
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             STAssertTrue(!error, @"!error");
             STAssertNotNil(result, @"nil result");

             NSDecimalNumber *width = [result objectForKey:@"width"];
             STAssertNotNil(width, @"couldn't get width");
             STAssertTrue(image2Size == (int)[width doubleValue], @"wrong width");
             NSLog(@"%@", width);
             
             [blocker signal];
         }];

    [connection start];
    [blocker wait];
    
    [connection release];
    [blocker release];
}

@end

#endif
