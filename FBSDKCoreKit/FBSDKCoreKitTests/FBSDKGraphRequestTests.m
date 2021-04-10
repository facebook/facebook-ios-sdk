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

static NSString *const _mockGraphPath = @"me";
static NSString *const _mockDefaultVersion = @"v9.0";
static NSString *const _mockPrefix = @"graph.";
static NSDictionary<NSString *, NSString *> *const _mockParameters(void)
{
  return @{@"fields" : @""};
}

static NSDictionary<NSString *, NSString *> *const _mockEmptyParameters(void)
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
{
  FBSDKGraphRequestConnection *_connection;
}

@end

@implementation FBSDKGraphRequestTests

- (void)setUp
{
  [super setUp];

  _connection = [FBSDKGraphRequestConnection new];
  [FBSDKAccessToken resetCurrentAccessTokenCache];
  [FBSDKGraphRequest reset];
}

#pragma mark - Tests

- (void)testCreatingGraphRequestWithDefaultSessionProxyFactory
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath];
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
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath
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
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath];

  [_connection addRequest:request
        completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [self verifyRequest:request expectedGraphPath:_mockGraphPath expectedParameters:_mockParameters() expectedTokenString:nil expectedVersion:_mockDefaultVersion expectedMethod:FBSDKHTTPMethodGET];
}

- (void)testStartRequestUsesRequestProvidedByFactory
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  TestGraphRequestConnection *fakeConnection = [TestGraphRequestConnection new];
  TestGraphRequestConnectionFactory *fakeConnectionFactory = [TestGraphRequestConnectionFactory createWithStubbedConnection:fakeConnection];
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath
                                                                 parameters:nil
                                                                tokenString:nil
                                                                 HTTPMethod:nil
                                                                      flags:FBSDKGraphRequestFlagNone
                                                          connectionFactory:fakeConnectionFactory];

  [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *_Nullable potentialConnection, id _Nullable result, NSError *_Nullable error) {
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
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters()];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];

  NSArray *requests = @[request1, request2, request3, request4];
  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:_mockGraphPath
      expectedParameters:_mockEmptyParameters()
     expectedTokenString:nil
         expectedVersion:_mockDefaultVersion
          expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testGraphRequestGETWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters()];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];

  NSArray *requests = @[request1, request2, request3, request4];
  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:_mockGraphPath
      expectedParameters:_mockParameters()
     expectedTokenString:nil
         expectedVersion:_mockDefaultVersion
          expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testDefaultPOSTParameters
{
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath HTTPMethod:FBSDKHTTPMethodPOST];
  [self verifyRequest:request
     expectedGraphPath:_mockGraphPath
    expectedParameters:_mockEmptyParameters()
   expectedTokenString:nil
       expectedVersion:_mockDefaultVersion
        expectedMethod:FBSDKHTTPMethodPOST];
}

- (void)testGraphRequestPOSTWithEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodPOST];
  NSArray *requests = @[request1, request2];

  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:_mockGraphPath
      expectedParameters:_mockEmptyParameters()
     expectedTokenString:nil
         expectedVersion:_mockDefaultVersion
          expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testGraphRequestPOSTWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodPOST];
  NSArray *requests = @[request1, request2];

  for (FBSDKGraphRequest *request in requests) {
    [self verifyRequest:request
       expectedGraphPath:_mockGraphPath
      expectedParameters:_mockParameters()
     expectedTokenString:nil
         expectedVersion:_mockDefaultVersion
          expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testSerializeURL
{
  NSString *baseURL = [FBSDKInternalUtility
                       facebookURLWithHostPrefix:_mockPrefix
                       path:_mockGraphPath
                       queryParameters:_mockEmptyParameters()
                       defaultVersion:_mockDefaultVersion
                       error:NULL].absoluteString;
  NSString *url = [FBSDKGraphRequest serializeURL:baseURL
                                           params:_mockParameters()
                                       httpMethod:FBSDKHTTPMethodPOST
                                         forBatch:YES];
  NSString *expectedURL = @"https://graph.facebook.com/v9.0/me?fields=";

  XCTAssertEqualObjects(url, expectedURL);

  // Test URLEncode and URLDecode
  NSString *expectedEncodedURL = @"https%3A%2F%2Fgraph.facebook.com%2Fv9.0%2Fme%3Ffields%3D";
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
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParameters()];
  XCTAssertEqual(
    request.tokenString,
    TestAccessTokenWallet.tokenString,
    "Should use the token string provider for the token string"
  );
  XCTAssertNotNil(request.tokenString, "Should have a concrete token string");
  [FBSDKGraphRequest reset];
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
