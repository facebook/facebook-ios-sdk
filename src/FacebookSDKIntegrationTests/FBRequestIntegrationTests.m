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

#import <UIKit/UIKit.h>

#import "FBGraphPlace.h"
#import "FBGraphUser.h"
#import "FBIntegrationTests.h"
#import "FBInternalSettings.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBTestSession.h"
#import "FBUtility.h"

#define UNIT_TEST_OPEN_GRAPH_NAMESPACE "facebooksdktests"

#if defined(FACEBOOKSDK_SKIP_COMMON_REQUEST_TESTS) || !defined(UNIT_TEST_OPEN_GRAPH_NAMESPACE)

#pragma message ("warning: Skipping FBRequestIntegrationTests")

#else

static NSString *const UNIT_TEST_IMAGE_URL = @"https://sphotos-b.xx.fbcdn.net/hphotos-ash4/387972_10152013102225492_1756755651_n.jpg";
static NSString *const UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE = @""UNIT_TEST_OPEN_GRAPH_NAMESPACE":test";

@interface FBRequestIntegrationTests : FBIntegrationTests
@end

@implementation FBRequestIntegrationTests

- (void)tearDown {
    [FBSession setActiveSession:nil];
    [super tearDown];
}

- (void)testRequestMe
{
    FBRequest *requestMe = [FBRequest requestForMe];
    [requestMe setSession:self.defaultTestSession];
    NSArray *results = [self sendRequests:requestMe, nil];

    XCTAssertNotNil(results, @"results");
    XCTAssertTrue([results isKindOfClass:[NSArray class]],
                 @"[results isKindOfClass:[NSArray class]]");
    XCTAssertTrue([results count] == 1, @"[results count] == 1");
    XCTAssertTrue(![[results objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[results objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[results objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"![[results objectAtIndex:0] isKindOfClass:[NSError class]]");

    id<FBGraphUser> me = [results objectAtIndex:0];
    XCTAssertNotNil(me.objectID, @"me.id");
    XCTAssertNotNil(me.name, @"me.name");
}

- (void)testRequestUploadPhoto
{
    FBRequest *uploadRequest = [FBRequest requestForUploadPhoto:[self createSquareTestImage:120]];
    [uploadRequest setSession:self.defaultTestSession];
    NSArray *responses = [self sendRequests:uploadRequest, nil];

    XCTAssertNotNil(responses, @"responses");
    XCTAssertTrue([responses isKindOfClass:[NSArray class]],
                 @"[responses isKindOfClass:[NSArray class]]");
    XCTAssertTrue([responses count] == 1, @"[responses count] == 1");
    XCTAssertTrue(![[responses objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[responses objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[responses objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[responses objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *replyData = (NSDictionary *)[responses objectAtIndex:0];
    XCTAssertNotNil([replyData objectForKey:@"id"],
                   @"[replyData objectForKey:id]");
    XCTAssertNotNil([replyData objectForKey:@"post_id"],
                   @"[replyData objectForKey:post_id]");
}

- (void)testRequestPlaceSearchWithNoSearchText
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.889468, -77.03524);
    FBRequest *searchRequest = [FBRequest requestForPlacesSearchAtCoordinate:coordinate
                                                              radiusInMeters:1000
                                                                resultsLimit:5
                                                                  searchText:nil];
    [searchRequest setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:searchRequest, nil];

    XCTAssertNotNil(response, @"response");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"[response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"[response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *firstResponse = (NSDictionary *)[response objectAtIndex:0];
    NSArray *data = (NSArray *)[firstResponse objectForKey:@"data"];
    XCTAssertTrue(data.count > 0, @"Did not get any responses");
}

- (void)testRequestPlaceSearchWithSearchText
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.889227, -77.049078);
    FBRequest *searchRequest = [FBRequest requestForPlacesSearchAtCoordinate:coordinate
                                                              radiusInMeters:200
                                                                resultsLimit:5
                                                                  searchText:@"Lincoln Memorial"];
    [searchRequest setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:searchRequest, nil];

    XCTAssertNotNil(response, @"response");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"[response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"[response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"[[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *firstResponse = (NSDictionary *)[response objectAtIndex:0];
    NSArray *data = (NSArray *)[firstResponse objectForKey:@"data"];

    BOOL found = NO;
    for (FBGraphObject *object in data) {
        if ([object[@"name"] rangeOfString:@"Lincoln Memorial"].location != NSNotFound) {
            found = YES;
            break;
        }
    }

    XCTAssertTrue(found, @"didn't find Lincoln Memorial");
}

- (void)testRestRequestGetUser {
    BOOL originalMode = [FBSettings isPlatformCompatibilityEnabled];
    [FBSettings enablePlatformCompatibility:YES];
    FBTestSession *session = self.defaultTestSession;

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                session.testUserID, @"uids",
                                @"uid,name", @"fields",
                                nil];
    FBRequest *request = [[[FBRequest alloc] initWithSession:session
                                                  restMethod:@"users.getInfo"
                                                  parameters:parameters
                                                  HTTPMethod:nil]
                          autorelease];

    NSArray *responses = [self sendRequests:request, nil];
    XCTAssertNotNil(responses, @"responses");

    NSArray *firstResponse = (NSArray *)[responses objectAtIndex:0];
    NSDictionary *firstResult = (NSDictionary *)[firstResponse objectAtIndex:0];
    XCTAssertNotNil(firstResult, @"firstResult");

    NSString *uid = [[firstResult objectForKey:@"uid"] stringValue];
    XCTAssertNotNil(uid, @"uid");
    XCTAssertTrue([session.testUserID isEqualToString:uid], @"don't match");
    [FBSettings enablePlatformCompatibility:originalMode];
}

- (NSArray *)sendRequests:(FBRequest *)firstRequest, ...
{
    NSMutableArray *requests = [[[NSMutableArray alloc] init] autorelease];

    [requests addObject:firstRequest];

    id vaRequest;
    va_list vaArguments;
    va_start(vaArguments, firstRequest);
    while ((vaRequest = va_arg(vaArguments, id))) {
        [requests addObject:vaRequest];
    }
    va_end(vaArguments);

    return [self sendRequestArray:requests];
}

- (NSArray *)sendRequestArray:(NSArray *)requests
{
    NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequestConnection *connection = [[[FBRequestConnection alloc] init] autorelease];
    FBRequestHandler handler =
    ^(FBRequestConnection *innerConnection, id result, NSError *error) {
        // Validate that we can assume in unit test that errors and results
        // are disjoint.
        XCTAssertTrue(![result isKindOfClass:[NSError class]],
                     @"![result isKindOfClass:[NSError class]]");
        [results addObject:(error ? error : result)];
        [blocker signal];
    };

    for (FBRequest *request in requests) {
        [connection addRequest:request completionHandler:handler];
    }

    [connection start];

    // FBRequestConnection sends its callbacks on the UI thread (this thread).
    // This code further assumes that all callbacks are sent in a loop on that
    // thread.  That is not guaranteed in the contract, and code anywhere other
    // than an SDK unit test should have a while loop to wait for the full set
    // of results.
    [blocker wait];
    XCTAssertTrue([results count] == [requests count],
                 @"[results count] == [requests count]");

    return results;
}

- (void)testGraphObjectTypedRequest
{
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBTestSession *session = self.defaultTestSession;
    [FBSession setActiveSession:session];

    [FBRequestConnection startWithGraphPath:@"100902843288017" // great fried chicken
                          completionHandler:^(FBRequestConnection *connection, id<FBGraphPlace> chicken, NSError *error) {
                              XCTAssertTrue([chicken.name isEqualToString:@"Ezell's Famous Chicken"], @"name wrong");
                              XCTAssertTrue([chicken.location.city isEqualToString:@"Woodinville"], @"city wrong");
                              XCTAssertTrue([chicken.location.state isEqualToString:@"WA"], @"state wrong");
                              [blocker signal];
                          }];

    [blocker wait];
}

- (void)testGraphObjectTypedRequest2
{
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBTestSession *session = self.defaultTestSession;
    [FBSession setActiveSession:session];

    [FBRequestConnection startWithGraphPath:session.testUserID
                          completionHandler:^(FBRequestConnection *connection, id<FBGraphUser> user, NSError *error) {
                              XCTAssertTrue([user.name isEqualToString:session.testUserName], @"Got unexpected user");
                              [blocker signal];
                          }];

    [blocker wait];
}

- (void)testSimpleGraphGet
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBSession setActiveSession:self.defaultTestSession];
    [FBRequestConnection startWithGraphPath:@"TourEiffel"
                          completionHandler:[self handlerExpectingSuccessSignaling:blocker]];

    [blocker wait];
    [blocker release];

}

- (void)testSimpleGraphGetWithExpectedFailure
{
    __block FBTestBlocker *blocker = [[FBTestBlocker alloc] init];
    [FBSession setActiveSession:self.defaultTestSession];
    [FBRequestConnection startWithGraphPath:@"-1"
                          completionHandler:[self handlerExpectingFailureSignaling:blocker]];
    [blocker wait];
    [blocker release];

}

- (id)postStatusUpdate
{
    id<FBGraphObject> status = [FBGraphObject graphObject];
    // Posting duplicate messages will generate an error.
    NSString *statusMessage = [NSString stringWithFormat:@"Check out my awesome new status update posted at %@.", [NSDate date]];
    [status setObject:statusMessage forKey:@"message"];

    return [self batchedPostAndGetWithSession:self.defaultTestSession
                                    graphPath:@"me/feed"
                                  graphObject:status];
}

- (id)postComment:(id)comment toStatusID:(NSString *)statusID
{
    NSString *graphPath = [NSString stringWithFormat:@"%@/comments", statusID];
    return [self batchedPostAndGetWithSession:self.defaultTestSession
                                    graphPath:graphPath
                                  graphObject:comment];
}

- (void)testCommentRoundTrip
{
    id createdStatus = [self postStatusUpdate];
    NSString *statusID = [createdStatus objectForKey:@"id"];
    id<FBGraphObject> comment = [FBGraphObject graphObject];
    NSString *commentMessage = @"It truly is a wonderful status update.";
    [comment setObject:commentMessage forKey:@"message"];

    id comment1 = [self postComment:comment toStatusID:statusID];
    NSString *comment1ID = [[[comment1 objectForKey:@"id"] retain] autorelease];
    NSString *comment1Message = [[[comment1 objectForKey:@"message"] retain] autorelease];

    // Try posting the same comment to the same status update. We need to clear its ID first.
    [comment1 removeObjectForKey:@"id"];
    id comment2 = [self postComment:comment1 toStatusID:statusID];

    NSString *comment2ID = [comment2 objectForKey:@"id"];
    NSString *comment2Message = [comment2 objectForKey:@"message"];

    XCTAssertFalse([comment1ID isEqualToString:comment2ID], @"ended up with the same comment");
    XCTAssertTrue([comment1Message isEqualToString:comment2Message], @"message not round-tripped");
}

- (NSDictionary *)createObjectWithCreateRequest:(FBRequest *)createRequest
{
    [createRequest setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:createRequest, nil];

    XCTAssertNotNil(response, @"create response");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"create: [response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"create: [response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"create: ![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"create: [[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");

    NSDictionary *firstResponse = (NSDictionary *)[response objectAtIndex:0];
    NSString *objectId = [firstResponse objectForKey:@"id"];
    XCTAssertNotNil(objectId, @"Did not get valid id for object creation");

    return [NSDictionary dictionaryWithObjectsAndKeys:objectId, @"id", nil];
}

- (void)checkResult:(NSDictionary *)result
      forProperties:(NSArray *)propertiesToCheck
withExpectedResults:(NSArray *)expectedResults
{
    if (propertiesToCheck) {
        for (int i = 0; i < [propertiesToCheck count]; i++) {
            NSString *propertyKey = [propertiesToCheck objectAtIndex:i];
            NSString *expectedResult = [expectedResults objectAtIndex:i];
            id objectToCheck = result;
            // Let caller tell us to look in the 'data' property by prepending 'data.' to the name of the property.
            if ([propertyKey hasPrefix:@"data."]) {
                propertyKey = [propertyKey substringFromIndex:5];
                objectToCheck = result[@"data"];
            }
            XCTAssertEqualObjects(expectedResult,
                                  [objectToCheck objectForKey:propertyKey],
                                  @"property check: %@ equals result[%@]",
                                  expectedResult,
                                  propertyKey);
        }
    }
}

- (NSString *)getAndCheckFBID:(NSString *)fbid
           checkForProperties:(NSArray *)propertiesToCheck
          withExpectedResults:(NSArray *)expectedResults
{
    FBRequest *request = [FBRequest requestForGraphPath:fbid];
    [request setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:request, nil];

    XCTAssertNotNil(response, @"get responses");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"get: [response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"get: [response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"get: ![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    NSDictionary *result = [response objectAtIndex:0];
    XCTAssertTrue([result isKindOfClass:[NSDictionary class]],
                 @"get: [[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");
    XCTAssertEqualObjects(fbid, [result valueForKey:@"id"],
                         @"get: [[response objectAtIndex:0] valueForKey:@\"id\"] equals fbid");

    [self checkResult:result forProperties:propertiesToCheck withExpectedResults:expectedResults];

    // If this was an object, return its post_action_id so we can check that too
    NSNumber *post_action_id = [result valueForKey:@"post_action_id"];
    return [NSString stringWithFormat:@"%@", post_action_id];

}

- (void)updateObjectWithRequest:(FBRequest *)updateRequest
             checkForProperties:(NSArray *)propertiesToCheck
                expectedResults:(NSArray *)expectedResults
{
    [updateRequest setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:updateRequest, nil];

    XCTAssertNotNil(response, @"update response");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"create: [response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"create: [response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"create: ![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    NSDictionary *objectResult = [response objectAtIndex:0];
    XCTAssertTrue([objectResult isKindOfClass:[NSDictionary class]],
                 @"get: [[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");
    [self checkResult:objectResult forProperties:propertiesToCheck withExpectedResults:expectedResults];
}

- (void)deleteId:(NSString *)fbid
{
    FBRequest *deleteRequest = [FBRequest requestForDeleteObject:fbid];
    [deleteRequest setSession:self.defaultTestSession];
    NSArray *response = [self sendRequests:deleteRequest, nil];

    XCTAssertNotNil(response, @"delete response");
    XCTAssertTrue([response isKindOfClass:[NSArray class]],
                 @"delete: [response isKindOfClass:[NSArray class]]");
    XCTAssertTrue([response count] == 1, @"delete: [response count] == 1");
    XCTAssertTrue(![[response objectAtIndex:0] isKindOfClass:[NSError class]],
                 @"delete: ![[response objectAtIndex:0] isKindOfClass:[NSError class]]");
    XCTAssertTrue([[response objectAtIndex:0] isKindOfClass:[NSDictionary class]],
                 @"delete: [[response objectAtIndex:0] isKindOfClass:[NSDictionary class]]");
    XCTAssertTrue([[[response objectAtIndex:0] objectForKey:@"FACEBOOK_NON_JSON_RESULT" ] isEqualToString:@"true"],
                 @"delete: [[response objectAtIndex:0] isEqualToString:@\"true\"]");

}

- (void)createAndGetAndDeleteObjectWithCreateRequest:(FBRequest *)createRequest
                            checkForObjectProperties:(NSArray *)objectPropertiesToCheck
                           withExpectedObjectResults:(NSArray *)objectPropertiesResults
                            checkForActionProperties:(NSArray *)actionPropertiesToCheck
                           withExpectedActionResults:(NSArray *)actionPropertiesResults
{
    // create an object
    NSDictionary *result = [self createObjectWithCreateRequest:createRequest];
    NSString *objectId = [result objectForKey:@"id"];

    // check that we can get the object and the action
    NSString *actionId = [self getAndCheckFBID:objectId
                            checkForProperties:objectPropertiesToCheck
                           withExpectedResults:objectPropertiesResults];
    [self getAndCheckFBID:actionId
       checkForProperties:actionPropertiesToCheck
      withExpectedResults:actionPropertiesResults];


    // delete the action (which will also delete the object)
    [self deleteId:actionId];
}

- (void)testBasicCreate
{
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObjectWithType:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE
                                                                          title:@"Object Create Test"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:nil
                                                               objectProperties:nil];
    [self createAndGetAndDeleteObjectWithCreateRequest:createRequest
                              checkForObjectProperties:nil
                             withExpectedObjectResults:nil
                              checkForActionProperties:nil
                             withExpectedActionResults:nil];
}

- (void)testCreateWithObjectProperties
{
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObjectWithType:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE
                                                                          title:@"Object Create Test"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:nil
                                                               objectProperties:@{@"a_property": @"some property"}];
    [self createAndGetAndDeleteObjectWithCreateRequest:createRequest
                              checkForObjectProperties:@[@"data.a_property"]
                             withExpectedObjectResults:@[@"some property"]
                              checkForActionProperties:nil
                             withExpectedActionResults:nil];
}

- (void)testCreateWithGraphObject
{
    NSMutableDictionary<FBGraphObject> *graphObject = [FBGraphObject openGraphObjectForPost];
    [graphObject setObject:@"Object Create Test" forKey:@"title"];
    [graphObject setObject:UNIT_TEST_IMAGE_URL forKey:@"image"];
    [graphObject setObject:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE forKey:@"type"];
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObject:(id)graphObject];
    [self createAndGetAndDeleteObjectWithCreateRequest:createRequest
                              checkForObjectProperties:nil
                             withExpectedObjectResults:nil
                              checkForActionProperties:nil
                             withExpectedActionResults:nil];
}

- (void)testCreateWithEverything
{
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObjectWithType:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE
                                                                          title:@"Object Create Test"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:@"some description"
                                                               objectProperties:nil];
    [self createAndGetAndDeleteObjectWithCreateRequest:createRequest
                              checkForObjectProperties:@[@"description"]
                             withExpectedObjectResults:@[@"some description"]
                              checkForActionProperties:nil
                             withExpectedActionResults:nil];
}

- (void)testUpdate
{
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObjectWithType:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE
                                                                          title:@"Object Create Test"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:nil
                                                               objectProperties:nil];
    NSDictionary *result = [self createObjectWithCreateRequest:createRequest];
    NSString *objectId = [result objectForKey:@"id"];

    // check that we can get the object and the action
    [self getAndCheckFBID:objectId
       checkForProperties:@[@"title"]
      withExpectedResults:@[@"Object Create Test"]];

    FBRequest *updateRequest = [FBRequest requestForUpdateOpenGraphObjectWithId:objectId
                                                                          title:@"New Title"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:@"new description"
                                                               objectProperties:nil];
    [self updateObjectWithRequest:updateRequest
               checkForProperties:@[@"title", @"description"]
                  expectedResults:@[@"New Title", @"new description"]];

    NSString *actionId = [self getAndCheckFBID:objectId
                            checkForProperties:@[@"title", @"description"]
                           withExpectedResults:@[@"New Title", @"new description"]];

    [self deleteId:actionId];
}

- (void)testUpdateWithGraphObject
{
    FBRequest *createRequest = [FBRequest requestForPostOpenGraphObjectWithType:UNIT_TEST_OPEN_GRAPH_TEST_OBJECT_NAMESPACE
                                                                          title:@"Object Create Test"
                                                                          image:UNIT_TEST_IMAGE_URL
                                                                            url:nil
                                                                    description:nil
                                                               objectProperties:nil];
    NSDictionary *result = [self createObjectWithCreateRequest:createRequest];
    NSString *objectId = [result objectForKey:@"id"];

    // check that we can get the object and the action
    [self getAndCheckFBID:objectId
       checkForProperties:@[@"title"]
      withExpectedResults:@[@"Object Create Test"]];

    NSMutableDictionary<FBGraphObject> *graphObject = [FBGraphObject openGraphObjectForPost];
    [graphObject setObject:objectId forKey:@"id"];
    [graphObject setObject:@"New Title" forKey:@"title"];
    [graphObject setObject:@"new description" forKey:@"description"];
    FBRequest *updateRequest = [FBRequest requestForUpdateOpenGraphObject:(id)graphObject];

    [self updateObjectWithRequest:updateRequest
               checkForProperties:@[@"title", @"description"]
                  expectedResults:@[@"New Title", @"new description"]];

    NSString *actionId = [self getAndCheckFBID:objectId
                            checkForProperties:@[@"title", @"description"]
                           withExpectedResults:@[@"New Title", @"new description"]];

    [self deleteId:actionId];
}

- (NSArray *)permissionsForDefaultTestSession
{
    return [NSArray arrayWithObjects:@"email",
            @"publish_actions",
            @"read_stream",
            nil];
}

- (void)testLegacyCompatibility
{
    FBTestSession *session = self.defaultTestSession;
    [FBSettings enablePlatformCompatibility:YES];
    FBTestBlocker *blocker = [[[FBTestBlocker alloc] init] autorelease];
    FBRequest *permissions = [FBRequest requestForGraphPath:@"me/permissions"];
    permissions.session = session;
    [permissions startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSArray *resultData = result[@"data"];
        XCTAssertTrue((resultData.count == 1 && [resultData[0] isKindOfClass:[NSDictionary class]] && resultData[0][@"permission"] == nil),
                     @"expected v1.0 me/permission results but got %@", result);
        [blocker signal];
    }];
    [blocker waitWithTimeout:10];
    [FBSettings enablePlatformCompatibility:NO];

    blocker = [[[FBTestBlocker alloc] init] autorelease];
    [permissions startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        NSArray *resultData = result[@"data"];
        XCTAssertFalse((resultData.count == 1 && [resultData[0] isKindOfClass:[NSDictionary class]] && resultData[0][@"permission"] == nil),
                     @"expected not v1.0 me/permission results but got %@", result);
        [blocker signal];
    }];
    [blocker waitWithTimeout:10];
}
@end

#endif
