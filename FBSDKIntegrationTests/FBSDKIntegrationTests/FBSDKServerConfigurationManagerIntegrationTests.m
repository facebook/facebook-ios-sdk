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

#import <objc/runtime.h>

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIntegrationTestCase.h"

@interface FBSDKServerConfigurationManagerIntegrationTests : FBSDKIntegrationTestCase
@end

@implementation FBSDKServerConfigurationManagerIntegrationTests

- (void)testLoadServerConfiguration
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed load"];
  FBSDKServerConfigurationManagerLoadBlock completionBlock = ^(FBSDKServerConfiguration *serverConfiguration,
                                                               NSError *error) {
    XCTAssertNotNil(serverConfiguration);
    XCTAssertNil(error, @"unexpected error: %@", error);
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:serverConfiguration];
    FBSDKServerConfiguration *restoredConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    FBSDKErrorRecoveryConfiguration *recoveryConfiguration = [restoredConfiguration.errorConfiguration recoveryConfigurationForCode:@"190" subcode:@"459" request:nil];
    XCTAssertEqual(FBSDKGraphRequestErrorCategoryRecoverable, recoveryConfiguration.errorCategory);
    [expectation fulfill];
  };
  [FBSDKServerConfigurationManager clearCache];
  // assert just in case default of 60 seconds when there's nothing loaded.
  XCTAssertEqual(60.0, [FBSDKServerConfigurationManager cachedServerConfiguration].sessionTimoutInterval);
  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:completionBlock];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation not fulfilled: %@", error);
  }];
  // now make sure  have the fetched value.
  XCTAssertEqual(61.0, [FBSDKServerConfigurationManager cachedServerConfiguration].sessionTimoutInterval);
}

- (void)testServerConfigurationVersion
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"completed load"];

  [FBSDKServerConfigurationManager clearCache];
  // assert default configuration version is equal
  XCTAssertEqual(FBSDKServerConfigurationVersion, [FBSDKServerConfigurationManager cachedServerConfiguration].version);

  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:
   ^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
     XCTAssertNotNil(serverConfiguration);
     XCTAssertNil(error, @"unexpected error: %@", error);
     XCTAssertEqual(FBSDKServerConfigurationVersion, serverConfiguration.version);

     // manually reset the version.
     Ivar ivar = class_getInstanceVariable([FBSDKServerConfiguration.class class], "_version");
     object_setIvar(serverConfiguration, ivar, 0);

     XCTAssertEqual(0, serverConfiguration.version);
     [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectations not fulfilled: %@", error);
  }];

  XCTestExpectation *expectation2 = [self expectationWithDescription:@"completed load2"];
  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:
    ^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
      XCTAssertNotNil(serverConfiguration);
      XCTAssertNil(error, @"unexpected error: %@", error);
      // assert it's got the correct version now, implying fresh request.
      XCTAssertEqual(FBSDKServerConfigurationVersion, serverConfiguration.version);
      [expectation2 fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectations not fulfilled: %@", error);
  }];

  // make sure we don't make another network request.
  XCTestExpectation *expectation3 = [self expectationWithDescription:@"completed load3"];
  id mock = [OCMockObject niceMockForClass:[FBSDKServerConfigurationManager class]];
  [[mock reject] processLoadRequestResponse:OCMOCK_ANY error:OCMOCK_ANY appID:OCMOCK_ANY];
  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:
   ^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
     XCTAssertNotNil(serverConfiguration);
     XCTAssertNil(error, @"unexpected error: %@", error);
     [expectation3 fulfill];
   }];
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error, @"expectation3 not fulfilled: %@", error);
  }];
}
@end
