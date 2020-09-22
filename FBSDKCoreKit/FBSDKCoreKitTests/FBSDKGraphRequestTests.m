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

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "FBSDKGraphRequest.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKUtility.h"

static NSString *const _mockGraphPath = @"me";
static NSString *const _mockDefaultVersion = @"v8.0";
static NSString *const _mockPrefix = @"graph.";
static NSDictionary<NSString *, NSString *> *const _mockParameters(void)
{
  return @{@"fields" : @""};
}

static NSDictionary<NSString *, NSString *> *const _mockEmptyParamter(void)
{
  return @{};
}

@interface FBSDKGraphRequestTests : XCTestCase
{
  FBSDKGraphRequestConnection *_mockConnection;
}

@end

@implementation FBSDKGraphRequestTests

- (void)setUp
{
  _mockConnection = [[FBSDKGraphRequestConnection alloc] init];
}

#pragma mark - Tests

- (void)testGraphRequestGETWithEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter()];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request5 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];

  [_mockConnection addRequest:request1
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request2
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request3
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request4
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request5
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];

  for (FBSDKGraphRequestMetadata *metadata in _mockConnection.requests) {
    [self verifyRequest:metadata.request expectedGraphPath:_mockGraphPath expectedParameters:_mockEmptyParamter() expectedTokenString:nil expectedVersion:_mockDefaultVersion expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testGraphRequestGETWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters()];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() flags:FBSDKGraphRequestFlagNone];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];
  FBSDKGraphRequest *request4 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodGET];

  [_mockConnection addRequest:request1
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request2
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request3
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request4
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];

  for (FBSDKGraphRequestMetadata *metadata in _mockConnection.requests) {
    [self verifyRequest:metadata.request expectedGraphPath:_mockGraphPath expectedParameters:_mockParameters() expectedTokenString:nil expectedVersion:_mockDefaultVersion expectedMethod:FBSDKHTTPMethodGET];
  }
}

- (void)testGraphRequestPOSTWithEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request3 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockEmptyParamter() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodPOST];

  [_mockConnection addRequest:request1
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request2
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request3
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];

  for (FBSDKGraphRequestMetadata *metadata in _mockConnection.requests) {
    [self verifyRequest:metadata.request expectedGraphPath:_mockGraphPath expectedParameters:_mockEmptyParamter() expectedTokenString:nil expectedVersion:_mockDefaultVersion expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testGraphRequestPOSTWithNonEmptyParameters
{
  FBSDKGraphRequest *request1 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequest *request2 = [[FBSDKGraphRequest alloc] initWithGraphPath:_mockGraphPath parameters:_mockParameters() tokenString:nil version:_mockDefaultVersion HTTPMethod:FBSDKHTTPMethodPOST];

  [_mockConnection addRequest:request1
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  [_mockConnection addRequest:request2
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];

  for (FBSDKGraphRequestMetadata *metadata in _mockConnection.requests) {
    [self verifyRequest:metadata.request expectedGraphPath:_mockGraphPath expectedParameters:_mockParameters() expectedTokenString:nil expectedVersion:_mockDefaultVersion expectedMethod:FBSDKHTTPMethodPOST];
  }
}

- (void)testSerializeURL
{
  NSString *baseURL = [FBSDKInternalUtility
                       facebookURLWithHostPrefix:_mockPrefix
                       path:_mockGraphPath
                       queryParameters:_mockEmptyParamter()
                       defaultVersion:_mockDefaultVersion
                       error:NULL].absoluteString;
  NSString *url = [FBSDKGraphRequest serializeURL:baseURL
                                           params:_mockParameters()
                                       httpMethod:FBSDKHTTPMethodPOST
                                         forBatch:YES];
  NSString *expectedURL = @"https://graph.facebook.com/v8.0/me?fields=";

  XCTAssertEqualObjects(url, expectedURL);

  // Test URLEncode and URLDecode
  NSString *expectedEncodedURL = @"https%3A%2F%2Fgraph.facebook.com%2Fv8.0%2Fme%3Ffields%3D";
  NSString *encodedSerializedURL = [FBSDKUtility URLEncode:expectedURL];

  XCTAssertEqualObjects(encodedSerializedURL, expectedEncodedURL);
  XCTAssertEqualObjects([FBSDKUtility URLDecode:encodedSerializedURL], expectedURL);
}

- (void)testIsAttachments
{
  id mockUIImage = [OCMockObject niceMockForClass:[UIImage class]];
  id mockData = [OCMockObject niceMockForClass:[NSData class]];
  id mockDataAttachments = [OCMockObject niceMockForClass:[FBSDKGraphRequestDataAttachment class]];

  XCTAssertTrue([FBSDKGraphRequest isAttachment:mockUIImage]);
  XCTAssertTrue([FBSDKGraphRequest isAttachment:mockData]);
  XCTAssertTrue([FBSDKGraphRequest isAttachment:mockDataAttachments]);

  id mockString = [OCMockObject niceMockForClass:[NSString class]];
  XCTAssertTrue(
    ![mockString isKindOfClass:[UIImage class]]
    && ![mockString isKindOfClass:[NSData class]]
    && ![mockString isKindOfClass:[FBSDKGraphRequestDataAttachment class]]
  );
  XCTAssertFalse([FBSDKGraphRequest isAttachment:mockString]);

  id mockDate = [OCMockObject niceMockForClass:[NSDate class]];
  XCTAssertTrue(
    ![mockDate isKindOfClass:[UIImage class]]
    && ![mockDate isKindOfClass:[NSData class]]
    && ![mockDate isKindOfClass:[FBSDKGraphRequestDataAttachment class]]
  );
  XCTAssertFalse([FBSDKGraphRequest isAttachment:mockDate]);
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
