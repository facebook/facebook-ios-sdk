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

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKLoginKitTests-Swift.h"

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginManagerLogger.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>
#else
 #import "FBSDKLoginManager.h"
 #import "FBSDKLoginManagerLogger.h"
#endif

@interface FBSDKLoginManagerLoggerTests : XCTestCase
@end

@implementation FBSDKLoginManagerLoggerTests

- (void)setUp
{
  [super setUp];

  [FBSDKSettings reset];
}

- (void)tearDown
{
  [super tearDown];

  [FBSDKSettings reset];
}

- (void)testCreatingWithMissingParametersWithTrackingEnabled
{
  XCTAssertNil(
    [FBSDKLoginManagerLogger loggerFromParameters:nil tracking:FBSDKLoginTrackingEnabled],
    "Should not create a logger with missing parameters"
  );
}

- (void)testCreatingWithEmptyParametersWithTrackingEnabled
{
  XCTAssertNil(
    [FBSDKLoginManagerLogger loggerFromParameters:@{} tracking:FBSDKLoginTrackingEnabled],
    "Should not create a logger with empty parameters"
  );
}

- (void)testCreatingWithParametersWithTrackingEnabled
{
  XCTAssertNotNil(
    [FBSDKLoginManagerLogger loggerFromParameters:self.validParameters tracking:FBSDKLoginTrackingEnabled],
    "Should create a logger with valid parameters and tracking enabled"
  );
}

- (void)testCreatingWithMissingParametersWithTrackingLimited
{
  XCTAssertNil(
    [FBSDKLoginManagerLogger loggerFromParameters:nil tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (void)testCreatingWithEmptyParametersWithTrackingLimited
{
  XCTAssertNil(
    [FBSDKLoginManagerLogger loggerFromParameters:@{} tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (void)testCreatingWithParametersWithTrackingLimited
{
  XCTAssertNil(
    [FBSDKLoginManagerLogger loggerFromParameters:self.validParameters tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (void)testInitializingWithMissingLoggingTokenWithTrackingEnabled
{
  XCTAssertNotNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:nil
                                                 tracking:FBSDKLoginTrackingEnabled],
    "Shouldn't create a logger with a missing logging token but it will"
  );
}

- (void)testInitializingWithNonStringLoggingTokenWithTrackingEnabled
{
  id token = @{};
  NSString *tokenString = (NSString *)token;

  XCTAssertNotNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:tokenString
                                                 tracking:FBSDKLoginTrackingEnabled],
    "Shouldn't create a logger with a non-string logging token but it will"
  );
}

- (void)testInitializingWithLoggingTokenWithTrackingEnabled
{
  XCTAssertNotNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                 tracking:FBSDKLoginTrackingEnabled],
    "Should create a logger with a logging token"
  );
}

- (void)testInitializingWithMissingLoggingTokenWithTrackingLimited
{
  XCTAssertNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:nil
                                                 tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (void)testInitializingWithNonStringLoggingTokenWithTrackingLimited
{
  id token = @{};
  NSString *tokenString = (NSString *)token;

  XCTAssertNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:tokenString
                                                 tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (void)testInitializingWithLoggingTokenWithTrackingLimited
{
  XCTAssertNil(
    [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:@"123"
                                                 tracking:FBSDKLoginTrackingLimited],
    "Should not create a logger with limited tracking"
  );
}

- (NSDictionary<NSString *, id> *)validParameters
{
  return @{@"state" : @"{\"challenge\":\"ibUuyvhzJW36TvC7BBYpasPHrXk%3D\",\"0_auth_logger_id\":\"A48F8D79-F2DF-4E04-B893-B29879A9A37B\",\"com.facebook.sdk_client_state\":true,\"3_method\":\"sfvc_auth\"}"};
}

@end
