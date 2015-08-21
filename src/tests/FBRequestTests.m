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

#import "FBRequest+Internal.h"
#import "FBRequestConnection+Internal.h"
#import "FBTestBlocker.h"
#import "FBTests.h"
#import "Facebook.h"

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBRequest (FBRequestTests)

- (FBRequestConnection *)createRequestConnection;
@property (readonly) NSString *versionPart;

@end

@interface TestFBRequest : FBRequest

@property (nonatomic, copy) FBRequestConnection * (^requestConnectionFactory)();

@end

@implementation TestFBRequest

- (FBRequestConnection *)createRequestConnection {
    if (self.requestConnectionFactory) {
        return self.requestConnectionFactory();
    }
    return [super createRequestConnection];
}

@end

#pragma mark - Test suite

@interface FBRequestTests : FBTests
@end

@implementation FBRequestTests

#pragma mark Test cases

- (void)testInitSetsDefaultsCorrectly {
    FBRequest *request = [[FBRequest alloc] init];

    XCTAssertNotNil(request);
    XCTAssertTrue([request.HTTPMethod isEqualToString:@"GET"]);
    XCTAssertNil(request.session);
    XCTAssertNil(request.graphPath);
    XCTAssertNil(request.restMethod);
    XCTAssertNil(request.graphPath);

    [request release];
}

- (void)testCanInitWithParameters {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                nil];
    
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:nil
                                                 parameters:parameters
                                                 HTTPMethod:nil];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.parameters[@"key1"] isEqualToString:@"value1"]);
    XCTAssertTrue([request.parameters[@"key2"] isEqualToString:@"value2"]);

    [request release];
}

- (void)testCanOverrideMigrationBundle {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"my bundle", @"migration_bundle",
                                nil];
    
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:nil
                                                 parameters:parameters
                                                 HTTPMethod:nil];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.parameters[@"migration_bundle"] isEqualToString:@"my bundle"]);
    XCTAssertTrue([request.description rangeOfString:@"value1"].location != NSNotFound);

    [request release];
}

- (void)testCanOverrideVersion {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:@"me/friends"
                                                 parameters:nil
                                                 HTTPMethod:nil];
    
    [request overrideVersionPartWith:@"v0.9"];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.versionPart isEqualToString:@"v0.9"]);

    [request release];
}

- (void)testSpecialDomain {
    [FBSettings setFacebookDomainPart:@"special.sb"];
    FBRequest *request = [[FBRequest alloc] initWithSession:nil graphPath:@"me/friends"];

    FBRequestConnection *dummy = [[FBRequestConnection alloc] init];
    NSString *actual = [dummy urlStringForSingleRequest:request forBatch:NO];


    assert([actual hasPrefix:@"https://graph.special.sb.facebook.com/v2.2/me/friends?"]);
    [request release];
    [FBSettings setFacebookDomainPart:nil];
}

- (void)testCanInitWithHTTPMethod {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:nil
                                                 parameters:nil
                                                 HTTPMethod:@"POST"];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.HTTPMethod isEqualToString:@"POST"]);

    [request release];
}

- (void)testCanInitWithGraphPath {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:@"MyGraphPath"
                                                 parameters:nil
                                                 HTTPMethod:nil];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.graphPath isEqualToString:@"MyGraphPath"]);
    XCTAssertTrue([request.description rangeOfString:@"MyGraphPath"].location != NSNotFound);

    [request release];
}

- (void)testCanInitWithRestMethod {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                 restMethod:@"amethod"
                                                 parameters:nil
                                                 HTTPMethod:nil];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.restMethod isEqualToString:@"amethod"]);
    XCTAssertTrue([request.description rangeOfString:@"amethod"].location != NSNotFound);

    [request release];
}

- (void)testCanInitWithSession {
    FBSession *session = [self createMockValidSession];
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:nil
                                                 parameters:nil
                                                 HTTPMethod:nil];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(session, request.session);

    [request release];
}

- (void)testInitSessionGraphPathHelper {
    FBSession *session = [self createMockValidSession];
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@"4"];
    XCTAssertNotNil(request);
    XCTAssertTrue([request.graphPath isEqualToString:@"4"]);
    XCTAssertEqualObjects(session, request.session);

    [request release];
}

- (void)testInitForPostHelper {
    FBSession *session = [self createMockValidSession];
    
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObject];
    [graphObject setObject:@"MyID" forKey:@"id"];
    
    FBRequest *request = [[FBRequest alloc] initForPostWithSession:session
                                                         graphPath:@"MyGraphPath"
                                                       graphObject:graphObject];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(session, request.session);
    XCTAssertTrue([request.graphPath isEqualToString:@"MyGraphPath"]);
    XCTAssertEqualObjects(request.graphObject, graphObject);
    XCTAssertTrue([request.HTTPMethod isEqualToString:@"POST"]);
    XCTAssertTrue([request.description rangeOfString:@"MyID"].location != NSNotFound);
    XCTAssertTrue([request.description rangeOfString:@"POST"].location != NSNotFound);
    
    [request release];
}

- (void)testCreateRequestConnection {
    FBRequest *request = [[FBRequest alloc] init];
    FBRequestConnection *connection = [request createRequestConnection];
    
    XCTAssertNotNil(request);
    XCTAssertTrue([connection isKindOfClass:[FBRequestConnection class]]);

    [request release];
}

- (void)testStartWithCompletionHandler {
    TestFBRequest *request = [[TestFBRequest alloc] init];
    
    FBRequestHandler handler = ^(FBRequestConnection *connection, id result, NSError *error) {
    };
    
    request.requestConnectionFactory = ^FBRequestConnection *{
        id connection = [OCMockObject mockForClass:[FBRequestConnection class]];
        [[connection expect] addRequest:request completionHandler:handler];
        [(FBRequestConnection *)[connection expect] start];
        return connection;
    };
    
    id connection = [request startWithCompletionHandler:handler];
    XCTAssertNotNil(connection);
    [connection verify];
    
    [request release];
    [handler release];
}

- (void)testDeprecatedProperties {
    // We lump all these into one test because we do not expect any development on any of these
    // properties going forward; this test just ensures they are not accidentally removed.
    FBRequest *request = [[FBRequest alloc] init];
    
    id<FBRequestDelegate> delegate = [OCMockObject mockForProtocol:@protocol(FBRequestDelegate)];
    request.delegate = delegate;
    XCTAssertEqualObjects(delegate, request.delegate);

    request.url = @"anurl";
    XCTAssertTrue([request.url isEqualToString:@"anurl"]);

    request.httpMethod = @"METHOD";
    XCTAssertTrue([request.HTTPMethod isEqualToString:@"METHOD"]);
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"value", @"key",
                                   nil];
    request.params = params;
    XCTAssertEqualObjects(params, request.params);
    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"value", @"key",
                                   nil];
    request.params = params;
    XCTAssertEqualObjects(params, request.params);

    NSURLConnection *connection = [[NSURLConnection alloc] init];
    request.connection = connection;
    XCTAssertEqualObjects(connection, request.connection);

    connection = [[NSURLConnection alloc] init];
    request.connection = connection;
    XCTAssertEqualObjects(connection, request.connection);

    NSMutableData *responseText = [[NSMutableData alloc] init];
    request.responseText = responseText;
    XCTAssertEqualObjects(responseText, request.responseText);
    responseText = [[NSMutableData alloc] init];
    request.responseText = responseText;
    XCTAssertEqualObjects(responseText, request.responseText);

    NSError *error = [[NSError alloc] init];
    request.error = error;
    XCTAssertEqualObjects(error, request.error);
    error = [[NSError alloc] init];
    request.error = error;
    XCTAssertEqualObjects(error, request.error);
    
    request.state = kFBRequestStateLoading;
    XCTAssertEqual(kFBRequestStateLoading, request.state);

    request.sessionDidExpire = YES;
    XCTAssertTrue(request.sessionDidExpire);
}

- (void)testDeprecatedMethods {
    // We lump all these into one test because we do not expect any development on any of these
    // methods going forward; this test just ensures they are not accidentally removed.
    FBRequest *request = [[FBRequest alloc] init];

    request.state = kFBRequestStateReady;
    XCTAssertFalse([request loading]);
    request.state = kFBRequestStateLoading;
    XCTAssertTrue([request loading]);

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                nil];
    NSString *url = [FBRequest serializeURL:@"http://www.example.com" params:parameters];
    XCTAssertTrue(([url rangeOfString:@"value2"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"http://www.example.com"].location != NSNotFound));

    UIImage *image = [[UIImage alloc] init];
    NSData *data = [[NSData alloc] init];
    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                image, @"animage",
                                data, @"somedata",
                                nil];
    url = [FBRequest serializeURL:@"http://www.example.com" params:parameters];

    XCTAssertTrue([url rangeOfString:@"value2"].location != NSNotFound);
    XCTAssertTrue([url rangeOfString:@"http://www.example.com"].location != NSNotFound);
    XCTAssertTrue([url rangeOfString:@"animage"].location == NSNotFound);
    XCTAssertTrue([url rangeOfString:@"somedata"].location == NSNotFound);
}

- (void)testSerializeUrl{
    NSDictionary *parameters = @{
                             @"key0": @100,
                             @"key1": @"200",
                             @"key2": @300.5};
    NSString *url = [FBRequest serializeURL:@"http://www.example.com" params:parameters];
    XCTAssertTrue(([url rangeOfString:@"http://www.example.com"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"key0"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"100"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"key1"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"200"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"key2"].location != NSNotFound));
    XCTAssertTrue(([url rangeOfString:@"300.5"].location != NSNotFound));
}

- (void)testRequestForMe {
    FBRequest *request = [FBRequest requestForMe];

    XCTAssertNotNil(request);
    XCTAssertTrue([@"me" isEqualToString:request.graphPath]);
}

- (void)testRequestForMyFriends {
    FBRequest *request = [FBRequest requestForMyFriends];

    XCTAssertNotNil(request);
    XCTAssertTrue([@"me/friends" isEqualToString:request.graphPath]);
}

- (void)testRequestForUploadPhotos {
    UIImage *image = [[UIImage alloc] init];
    FBRequest *request = [FBRequest requestForUploadPhoto:image];

    XCTAssertNotNil(request);
    XCTAssertNotNil(request.parameters[@"picture"]);
    XCTAssertTrue([@"me/photos" isEqualToString:request.graphPath]);
}

- (void)testRequestForGraphPath {
    FBRequest *request = [FBRequest requestForGraphPath:@"apath"];
    
    XCTAssertNotNil(request);
    XCTAssertTrue([@"apath" isEqualToString:request.graphPath]);
}

- (void)testRequestForPostWithGraphPath {
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObject];
    [graphObject setObject:@"value" forKey:@"key"];
    FBRequest *request = [FBRequest requestForPostWithGraphPath:@"apath"
                                                    graphObject:graphObject];

    XCTAssertNotNil(request);
    XCTAssertTrue([request.graphObject[@"key"] isEqualToString:@"value"]);
    XCTAssertTrue([@"apath" isEqualToString:request.graphPath]);
    XCTAssertTrue([@"POST" isEqualToString:request.HTTPMethod]);
}

- (void)testRequestForPostStatusUpdate {
    NSDictionary<FBGraphObject> *place = [FBGraphObject graphObject];
    [place setObject:@"placeid" forKey:@"id"];
    
    NSArray *tags = [NSArray arrayWithObjects:@"id1", @"id2", nil];
    
    FBRequest *request = [FBRequest requestForPostStatusUpdate:@"my status"
                                                         place:place
                                                          tags:tags];

    XCTAssertNotNil(request);
    XCTAssertTrue([@"me/feed" isEqualToString:request.graphPath]);
    XCTAssertTrue([@"POST" isEqualToString:request.HTTPMethod]);
    XCTAssertTrue([request.parameters[@"message"] isEqualToString:@"my status"]);
    XCTAssertTrue([request.parameters[@"place"] isEqualToString:@"placeid"]);
    XCTAssertTrue([request.parameters[@"tags"] isEqualToString:@"id1,id2"]);
}

- (void)testRequestForPostStatusUpdateHelper {
    FBRequest *request = [FBRequest requestForPostStatusUpdate:@"my status"];

    XCTAssertNotNil(request);
    XCTAssertTrue([@"me/feed" isEqualToString:request.graphPath]);
    XCTAssertTrue([@"POST" isEqualToString:request.HTTPMethod]);
    XCTAssertTrue([request.parameters[@"message"] isEqualToString:@"my status"]);
    XCTAssertNil(request.parameters[@"place"]);
    XCTAssertNil(request.parameters[@"tags"]);
}

- (void)testRequestWithGraphPath {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                nil];

    FBRequest *request = [FBRequest requestWithGraphPath:@"apath"
                                             parameters:parameters
                                             HTTPMethod:@"POST"];
    XCTAssertNotNil(request);
    XCTAssertTrue([@"apath" isEqualToString:request.graphPath]);
    XCTAssertTrue([@"POST" isEqualToString:request.HTTPMethod]);
    XCTAssertTrue([request.parameters[@"key1"] isEqualToString:@"value1"]);
    XCTAssertTrue([request.parameters[@"key2"] isEqualToString:@"value2"]);
}

- (void)testRequestForPlacesSearch {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(23.5, 45.5);
    FBRequest *request = [FBRequest requestForPlacesSearchAtCoordinate:coord
                                                        radiusInMeters:1234
                                                          resultsLimit:789
                                                            searchText:@"restaurant"];
    XCTAssertNotNil(request);
    XCTAssertTrue([@"search" isEqualToString:request.graphPath]);
    XCTAssertTrue([@"GET" isEqualToString:request.HTTPMethod]);
    XCTAssertTrue([request.parameters[@"type"] isEqualToString:@"place"]);
    XCTAssertTrue([request.parameters[@"limit"] isEqualToString:@"789"]);
    XCTAssertTrue([request.parameters[@"distance"] isEqualToString:@"1234"]);
    XCTAssertTrue([request.parameters[@"q"] isEqualToString:@"restaurant"]);
    XCTAssertTrue([request.parameters[@"center"] rangeOfString:@"23.5"].location != NSNotFound);
    XCTAssertTrue([request.parameters[@"center"] rangeOfString:@"45.5"].location != NSNotFound);
}

- (void)testRequestForPlacesSearchDoesNotRequireSearchText {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(23.5, 45.5);
    FBRequest *request = [FBRequest requestForPlacesSearchAtCoordinate:coord
                                                        radiusInMeters:1234
                                                          resultsLimit:789
                                                            searchText:nil];
    XCTAssertNil(request.parameters[@"q"]);
}

#pragma mark Helpers


- (FBSession *)createMockValidSession {
    FBSession *session = [OCMockObject mockForClass:[FBSession class]];
    return session;
}

@end
