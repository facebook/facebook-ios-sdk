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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#ifdef BUCK
 #import <FBSDKLoginKit+Internal/FBSDKLoginManagerLogger.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>
#else
 #import "FBSDKLoginManager.h"
 #import "FBSDKLoginManagerLogger.h"
#endif

@interface FBSDKAppEvents (Testing)

+ (FBSDKAppEvents *)singleton;

- (void)instanceLogEvent:(FBSDKAppEventName)eventName
              valueToSum:(NSNumber *)valueToSum
              parameters:(NSDictionary *)parameters
      isImplicitlyLogged:(BOOL)isImplicitlyLogged
             accessToken:(FBSDKAccessToken *)accessToken;

@end

@interface FBSDKLoginManagerLoggerTests : XCTestCase
@end

@implementation FBSDKLoginManagerLoggerTests
{
  id _appEventsMock;
  id _loginManagerMock;
}

- (void)setUp
{
  [super setUp];
  _loginManagerMock = OCMClassMock(FBSDKLoginManager.class);
  // Set up AppEvents singleton mock
  _appEventsMock = OCMClassMock(FBSDKAppEvents.class);
  OCMStub([_appEventsMock singleton]).andReturn(_appEventsMock);
}

- (void)tearDown
{
  [super tearDown];
  [_loginManagerMock stopMocking];
  _loginManagerMock = nil;
  [_appEventsMock stopMocking];
  _appEventsMock = nil;
}

- (void)testExtrasForAddSingleLoggingExtra
{
  FBSDKLoginManagerLogger *logger = [[FBSDKLoginManagerLogger alloc] initWithLoggingToken:nil];
  BOOL (^verifyParameterContents)(NSDictionary *) = ^BOOL (NSDictionary *parameters) {
    NSString *extras = [FBSDKTypeUtility dictionary:parameters objectForKey:@"6_extras" ofType:NSString.class];
    NSDictionary *extrasDictionary = [FBSDKBasicUtility objectForJSONString:extras error:nil];
    XCTAssertEqualObjects([FBSDKTypeUtility dictionary:extrasDictionary objectForKey:@"test_extra_key" ofType:NSString.class], @"test_extra_value");
    return YES;
  };

  [logger addSingleLoggingExtra:@"test_extra_value" forKey:@"test_extra_key"];
  [logger startSessionForLoginManager:_loginManagerMock];

  OCMVerify(
    [_appEventsMock instanceLogEvent:OCMArg.any
                          valueToSum:OCMArg.any
                          parameters:[OCMArg checkWithBlock:verifyParameterContents]
                  isImplicitlyLogged:OCMArg.any
                         accessToken:OCMArg.any]
  );
}

@end
