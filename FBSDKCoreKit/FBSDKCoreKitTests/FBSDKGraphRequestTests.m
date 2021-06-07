// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <XCTest/XCTest.h>

@import TestTools;

#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+GraphRequestConnecting.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestConnectionProviding.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKUtility.h"

static NSString *const path = @"me";
static NSString *const version = @"v11.0";
static NSString *const prefix = @"graph.";
static NSDictionary<NSString *, NSString *> *const parameters(void)
{
  return @{@"fields" : @""};
}

static NSDictionary<NSString *, NSString *> *const emptyParameters(void)
{
  return @{};
}

@interface FBSDKGraphRequest (Testing)

@property (nonatomic, strong) id<FBSDKGraphRequestConnectionProviding> connectionFactory;

+ (void)reset;

@end

@interface FBSDKAccessToken (Testing)

+ (void)resetCurrentAccessTokenCache;

@end

@interface FBSDKGraphRequestTests : XCTestCase
@end

@implementation FBSDKGraphRequestTests

- (void)setUp
{
  [super setUp];

  [FBSDKAccessToken resetCurrentAccessTokenCache];
  [FBSDKGraphRequest reset];
}

#pragma mark - Tests

- (void)testCreatingGraphRequestWithDefaultSessionProxyFactory
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path];
  NSObject *factory = (NSObject *)request.connectionFactory;
  XCTAssertEqualObjects(
    factory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "A graph request should have the correct concrete session provider by default"
  );
}

- (void)testCreatingWithCustomUrlSessionProxyFactory
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  TestGraphRequestConnectionFactory *fakeConnectionFactory = [TestGraphRequestConnectionFactory createWithStubbedConnection:connection];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                 parameters:nil
                                                                tokenString:nil
                                                                 HTTPMethod:nil
                                                                      flags:FBSDKGraphRequestFlagNone
                                                          connectionFactory:fakeConnectionFactory];
  NSObject *factory = (NSObject *)request.connectionFactory;

  XCTAssertEqualObjects(
    factory.class,
    TestGraphRequestConnectionFactory.class,
    "A graph request should persist the session factory it was created with"
  );
}

- (void)testDefaultGETParameters
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path];

  [self verifyRequest:request expectedGraphPath:path
    expectedParameters:parameters()
   expectedTokenString:nil
       expectedVersion:version
        expectedMethod:FBSDKHTTPMethodGET];
}

- (void)testStartRequestUsesRequestProvidedByFactory
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  TestGraphRequestConnection *fakeConnection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *fakeConnectionFactory = [TestGraphRequestConnectionFactory createWithStubbedConnection:fakeConnection];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                 parameters:nil
                                                                tokenString:nil
                                                                 HTTPMethod:nil
                                                                      flags:FBSDKGraphRequestFlagNone
                                                          connectionFactory:fakeConnectionFactory];

  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> _Nullable potentialConnection, id _Nullable result, NSError *_Nullable error) {
    XCTAssertEqualObjects(result, self.name);
    [expectation fulfill];
  }];

  fakeConnection.capturedCompletion(nil, self.name, nil);
  XCTAssertEqual(
    fakeConnection.startCallCount,
    1,
    "The graph request should start the connection once"
  );

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testGraphRequestGETWithEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters()];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodGET];

  NSArray *requests = @[request1, request2, request3, request4];
  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:path
      expectedParameters:emptyParameters()
     expectedTokenString:nil
         expectedVersion:version
          expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testGraphRequestGETWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters()];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodGET];

  NSArray *requests = @[request1, request2, request3, request4];
  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:path
      expectedParameters:parameters()
     expectedTokenString:nil
         expectedVersion:version
          expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testDefaultPOSTParameters
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path HTTPMethod:FBSDKHTTPMethodPOST];
  [self verifyRequest:request
     expectedGraphPath:path
    expectedParameters:emptyParameters()
   expectedTokenString:nil
       expectedVersion:version
        expectedMethod:FBSDKHTTPMethodPOST];
}

- (void)testGraphRequestPOSTWithEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodPOST];
  NSArray *requests = @[request1, request2];

  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:path
      expectedParameters:emptyParameters()
     expectedTokenString:nil
         expectedVersion:version
          expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testGraphRequestPOSTWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:parameters() tokenString:nil version:version HTTPMethod:FBSDKHTTPMethodPOST];
  NSArray *requests = @[request1, request2];

  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:path
      expectedParameters:parameters()
     expectedTokenString:nil
         expectedVersion:version
          expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testSerializeURL
{
  NSString *baseURL = [FBSDKInternalUtility
                       facebookURLWithHostPrefix:prefix
                       path:path
                       queryParameters:emptyParameters()
                       defaultVersion:version
                       error:NULL].absoluteString;
  NSString *url = [FBSDKGraphRequest serializeURL:baseURL
                                           params:parameters()
                                       httpMethod:FBSDKHTTPMethodPOST
                                         forBatch:YES];
  NSString *expectedURL = @"https://graph.facebook.com/v11.0/me?fields=";

  XCTAssertEqualObjects(url, expectedURL);

  // Test URLEncode and URLDecode
  NSString *expectedEncodedURL = @"https%3A%2F%2Fgraph.facebook.com%2Fv11.0%2Fme%3Ffields%3D";
  NSString *encodedSerializedURL = [FBSDKUtility URLEncode:expectedURL];

  XCTAssertEqualObjects(encodedSerializedURL, expectedEncodedURL);
  XCTAssertEqualObjects([FBSDKUtility URLDecode:encodedSerializedURL], expectedURL);
}

- (void)testIsAttachments
{
  id image = [UIImage new];
  id data = [NSData new];
  id dataAttachment = [[FBSDKGraphRequestDataAttachment alloc] initWithData:data
                                                                   filename:@"fakefile"
                                                                contentType:@"foo"];
  XCTAssertTrue([FBSDKGraphRequest isAttachment:image]);
  XCTAssertTrue([FBSDKGraphRequest isAttachment:data]);
  XCTAssertTrue([FBSDKGraphRequest isAttachment:dataAttachment]);

  id string = [NSString new];
  XCTAssertTrue(
    ![string isKindOfClass:UIImage.class]
    && ![string isKindOfClass:NSData.class]
    && ![string isKindOfClass:FBSDKGraphRequestDataAttachment.class]
  );
  XCTAssertFalse([FBSDKGraphRequest isAttachment:string]);

  id date = [NSDate date];
  XCTAssertTrue(
    ![date isKindOfClass:[UIImage class]]
    && ![date isKindOfClass:[NSData class]]
    && ![date isKindOfClass:[FBSDKGraphRequestDataAttachment class]]
  );
  XCTAssertFalse([FBSDKGraphRequest isAttachment:date]);
}

- (void)testCreateRequestWithDefaultTokenString
{
  TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken;
  [FBSDKGraphRequest setCurrentAccessTokenStringProvider:[TestAccessTokenWallet class]];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path parameters:emptyParameters()];
  XCTAssertEqual(
    request.tokenString,
    TestAccessTokenWallet.tokenString,
    "Should use the token string provider for the token string"
  );
  XCTAssertNotNil(request.tokenString, "Should have a concrete token string");
  [FBSDKGraphRequest reset];
}

- (void)testDebuggingHelpers
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path
                                                                 parameters:parameters()
                                                                 HTTPMethod:FBSDKHTTPMethodPOST];

  NSString *expectedDescriptionPart = @"graphPath: me, HTTPMethod: POST, parameters: {\n    fields = " "";
  XCTAssertTrue(
    [[request description] containsString:expectedDescriptionPart],
    "Requests should have useful information in their description"
  );
}

- (void)testDebuggingMetadata
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:path];
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                                                         completionHandler:nil
                                                                           batchParameters:@{}];
  XCTAssertTrue(
    [metadata.description containsString:@"request: "],
    "Request metadata should include information about the request"
  );
}

#pragma mark - helper function

- (void)verifyRequest:(FBSDKGraphRequest *)request
    expectedGraphPath:(NSString *)expectedGraphPath
   expectedParameters:(NSDictionary<NSString *, NSString *> *)expectedParameters
  expectedTokenString:(NSString *)expectedTokenString
      expectedVersion:(NSString *)expectedVersion
       expectedMethod:(FBSDKHTTPMethod)expectedMethod
{
  XCTAssertEqualObjects(request.graphPath, expectedGraphPath);
  XCTAssertEqualObjects(request.parameters, expectedParameters);
  XCTAssertEqualObjects(request.tokenString, expectedTokenString);
  XCTAssertEqualObjects(request.version, expectedVersion);
  XCTAssertEqualObjects(request.HTTPMethod, expectedMethod);
}

@end
