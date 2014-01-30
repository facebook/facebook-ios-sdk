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

#import "FBRequestTests.h"
#import "FBRequest.h"
#import "FBTestBlocker.h"
#import "FBSDKVersion.h"
#import "Facebook.h"

#import <OHHTTPStubs/OHHTTPStubs.h>

// This is just to silence compiler warnings since we access internal methods in some tests.
@interface FBRequest (Internal)

- (FBRequestConnection *)createRequestConnection;

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

@implementation FBRequestTests {
//    FBTestBlocker *_blocker;
//    BOOL _handlerCalled;
//    FBURLConnectionHandler _handler;
}

- (void)setUp {
//    _blocker = [[FBTestBlocker alloc] initWithExpectedSignalCount:1];
//    _handlerCalled = NO;
//    _handler = nil;
}

- (void)tearDown {
//    [_blocker release];
//    _blocker = nil;
//    [_handler release];
//    _handler = nil;
    
//    [OHHTTPStubs removeAllRequestHandlers];
}

#pragma mark Test cases

- (void)testInitSetsDefaultsCorrectly {
    FBRequest *request = [[FBRequest alloc] init];
    
    assertThat(request, notNilValue());
    assertThat(request.HTTPMethod, equalTo(@"GET"));    
    assertThat(request.parameters, hasEntry(@"migration_bundle", FB_IOS_SDK_MIGRATION_BUNDLE));
    assertThat(request.session, nilValue());
    assertThat(request.graphPath, nilValue());
    assertThat(request.restMethod, nilValue());
    assertThat(request.graphPath, nilValue());
    
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
    assertThat(request, notNilValue());
    assertThat(request.parameters, hasEntries(@"key1", @"value1", @"key2", @"value2", nil));
    
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
    assertThat(request, notNilValue());
    assertThat(request.parameters, hasEntry(@"migration_bundle", @"my bundle"));
    assertThat([request description], containsString(@"value1"));
    
    [request release];
}

- (void)testCanInitWithHTTPMethod {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:nil
                                                 parameters:nil
                                                 HTTPMethod:@"POST"];
    assertThat(request, notNilValue());
    assertThat(request.HTTPMethod, equalTo(@"POST"));
    
    [request release];
}

- (void)testCanInitWithGraphPath {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                  graphPath:@"MyGraphPath"
                                                 parameters:nil
                                                 HTTPMethod:nil];
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"MyGraphPath"));
    assertThat([request description], containsString(@"MyGraphPath"));
    
    [request release];
}

- (void)testCanInitWithRestMethod {
    FBRequest *request = [[FBRequest alloc] initWithSession:nil
                                                 restMethod:@"amethod"
                                                 parameters:nil
                                                 HTTPMethod:nil];
    assertThat(request, notNilValue());
    assertThat(request.restMethod, equalTo(@"amethod"));
    assertThat([request description], containsString(@"amethod"));
    
    [request release];
}

- (void)testCanInitWithSession {
    FBSession *session = [self createMockValidSession];
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:nil
                                                 parameters:nil
                                                 HTTPMethod:nil];
    assertThat(request, notNilValue());
    assertThat(request.session, equalTo(session));
    
    [request release];
}

- (void)testInitSessionGraphPathHelper {
    FBSession *session = [self createMockValidSession];
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                  graphPath:@"4"];
    assertThat(request, notNilValue());
    assertThat(request.session, equalTo(session));
    assertThat(request.graphPath, equalTo(@"4"));
    
    [request release];
}

- (void)testInitForPostHelper {
    FBSession *session = [self createMockValidSession];
    
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObject];
    [graphObject setObject:@"MyID" forKey:@"id"];
    
    FBRequest *request = [[FBRequest alloc] initForPostWithSession:session
                                                         graphPath:@"MyGraphPath"
                                                       graphObject:graphObject];
    assertThat(request, notNilValue());
    assertThat(request.session, equalTo(session));
    assertThat(request.graphPath, equalTo(@"MyGraphPath"));
    assertThat(request.graphObject, equalTo(graphObject));
    assertThat(request.HTTPMethod, equalTo(@"POST"));
    assertThat([request description], containsString(@"MyID"));
    assertThat([request description], containsString(@"POST"));
    
    [request release];
}

- (void)testCreateRequestConnection {
    FBRequest *request = [[FBRequest alloc] init];
    FBRequestConnection *connection = [request createRequestConnection];
    
    assertThat(connection, notNilValue());
    assertThat(connection, instanceOf([FBRequestConnection class]));
    
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
    assertThat(connection, notNilValue());
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
    assertThat(request.delegate, equalTo(delegate));
    
    request.url = @"anurl";
    assertThat(request.url, equalTo(@"anurl"));
    
    request.httpMethod = @"METHOD";
    assertThat(request.httpMethod, equalTo(@"METHOD"));
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"value", @"key",
                                   nil];
    request.params = params;
    assertThat(request.params, equalTo(params));
    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"value", @"key",
                                   nil];
    request.params = params;
    assertThat(request.params, equalTo(params));
    
    NSURLConnection *connection = [[NSURLConnection alloc] init];
    request.connection = connection;
    assertThat(request.connection, equalTo(connection));
    connection = [[NSURLConnection alloc] init];
    request.connection = connection;
    assertThat(request.connection, equalTo(connection));

    NSMutableData *responseText = [[NSMutableData alloc] init];
    request.responseText = responseText;
    assertThat(request.responseText, equalTo(responseText));
    responseText = [[NSMutableData alloc] init];
    request.responseText = responseText;
    assertThat(request.responseText, equalTo(responseText));

    NSError *error = [[NSError alloc] init];
    request.error = error;
    assertThat(request.error, equalTo(error));
    error = [[NSError alloc] init];
    request.error = error;
    assertThat(request.error, equalTo(error));
    
    request.state = kFBRequestStateLoading;
    assertThatInteger(request.state, equalToInteger(kFBRequestStateLoading));
    
    request.sessionDidExpire = YES;
    assertThatBool(request.sessionDidExpire, equalToBool(YES));
}

- (void)testDeprecatedMethods {
    // We lump all these into one test because we do not expect any development on any of these
    // methods going forward; this test just ensures they are not accidentally removed.
    FBRequest *request = [[FBRequest alloc] init];

    request.state = kFBRequestStateReady;
    assertThatBool([request loading], equalToBool(NO));
    request.state = kFBRequestStateLoading;
    assertThatBool([request loading], equalToBool(YES));

    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                nil];
    NSString *url = [FBRequest serializeURL:@"http://www.example.com" params:parameters];
    assertThat(url, containsString(@"value2"));
    assertThat(url, containsString(@"http://www.example.com"));

    UIImage *image = [[UIImage alloc] init];
    NSData *data = [[NSData alloc] init];
    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                image, @"animage",
                                data, @"somedata",
                                nil];
    url = [FBRequest serializeURL:@"http://www.example.com" params:parameters];
    assertThat(url, containsString(@"value2"));
    assertThat(url, containsString(@"http://www.example.com"));
    assertThat(url, isNot(containsString(@"animage")));
    assertThat(url, isNot(containsString(@"somedata")));
}

- (void)testRequestForMe {
    FBRequest *request = [FBRequest requestForMe];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"me"));
}

- (void)testRequestForMyFriends {
    FBRequest *request = [FBRequest requestForMyFriends];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"me/friends"));
}

- (void)testRequestForUploadPhotos {
    UIImage *image = [[UIImage alloc] init];
    FBRequest *request = [FBRequest requestForUploadPhoto:image];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"me/photos"));
    assertThat(request.parameters, hasKey(@"picture"));
}

- (void)testRequestForGraphPath {
    FBRequest *request = [FBRequest requestForGraphPath:@"apath"];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"apath"));
}

- (void)testRequestForPostWithGraphPath {
    NSDictionary<FBGraphObject> *graphObject = [FBGraphObject graphObject];
    [graphObject setObject:@"value" forKey:@"key"];
    FBRequest *request = [FBRequest requestForPostWithGraphPath:@"apath"
                                                    graphObject:graphObject];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"apath"));
    assertThat(request.graphObject, hasEntry(@"key", @"value"));
    assertThat(request.HTTPMethod, equalTo(@"POST"));
}

- (void)testRequestForPostStatusUpdate {
    NSDictionary<FBGraphObject> *place = [FBGraphObject graphObject];
    [place setObject:@"placeid" forKey:@"id"];
    
    NSArray *tags = [NSArray arrayWithObjects:@"id1", @"id2", nil];
    
    FBRequest *request = [FBRequest requestForPostStatusUpdate:@"my status"
                                                         place:place
                                                          tags:tags];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"me/feed"));
    assertThat(request.HTTPMethod, equalTo(@"POST"));
    assertThat(request.parameters, hasEntry(@"message", @"my status"));
    assertThat(request.parameters, hasEntry(@"place", @"placeid"));
    assertThat(request.parameters, hasEntry(@"tags", @"id1,id2"));
}

- (void)testRequestForPostStatusUpdateHelper {
    FBRequest *request = [FBRequest requestForPostStatusUpdate:@"my status"];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"me/feed"));
    assertThat(request.HTTPMethod, equalTo(@"POST"));
    assertThat(request.parameters, hasEntry(@"message", @"my status"));
    assertThat(request.parameters, isNot(hasKey(@"place")));
    assertThat(request.parameters, isNot(hasKey(@"tags")));
}

- (void)testRequestWithGraphPath {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"value1", @"key1",
                                @"value2", @"key2",
                                nil];

    FBRequest *request = [FBRequest requestWithGraphPath:@"apath"
                                             parameters:parameters
                                             HTTPMethod:@"POST"];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"apath"));
    assertThat(request.HTTPMethod, equalTo(@"POST"));
    assertThat(request.parameters, hasEntries(@"key1", @"value1", @"key2", @"value2", nil));
}

- (void)testRequestForPlacesSearch {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(23.5, 45.5);
    FBRequest *request = [FBRequest requestForPlacesSearchAtCoordinate:coord
                                                        radiusInMeters:1234
                                                          resultsLimit:789
                                                            searchText:@"restaurant"];
    
    assertThat(request, notNilValue());
    assertThat(request.graphPath, equalTo(@"search"));
    assertThat(request.HTTPMethod, equalTo(@"GET"));
    assertThat(request.parameters, hasEntry(@"type", @"place"));
    assertThat(request.parameters, hasEntry(@"limit", @"789"));
    assertThat(request.parameters, hasEntry(@"distance", @"1234"));
    assertThat(request.parameters, hasEntry(@"q", @"restaurant"));
    NSString *center = [request.parameters objectForKey:@"center"];
    assertThat(center, containsString(@"23.5"));
    assertThat(center, containsString(@"45.5"));
}

- (void)testRequestForPlacesSearchDoesNotRequireSearchText {
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(23.5, 45.5);
    FBRequest *request = [FBRequest requestForPlacesSearchAtCoordinate:coord
                                                        radiusInMeters:1234
                                                          resultsLimit:789
                                                            searchText:nil];
    
    assertThat(request.parameters, isNot(hasKey(@"q")));
}

#pragma mark Helpers


- (FBSession *)createMockValidSession {
    FBSession *session = [OCMockObject mockForClass:[FBSession class]];
    return session;
}

@end
