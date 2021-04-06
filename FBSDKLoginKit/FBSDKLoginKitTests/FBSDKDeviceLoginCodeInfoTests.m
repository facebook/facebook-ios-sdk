// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to
// use, copy, modify, and distribute this software in source code or binary form
// for use in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h>
#else
 #import "FBSDKDeviceLoginCodeInfo.h"
#endif

static NSString *const _validIdentifier = @"abcd";
static NSString *const _validIdentifier2 = @"123";
static NSString *const _validIdentifier3 = @"123abc";
static NSString *const _emptyIdentifier = @"";
static NSString *const _validLoginCode = @"abcd";
static NSString *const _validLoginCode2 = @"123";
static NSString *const _validLoginCode3 = @"123abc";
static NSString *const _emptyLoginCode = @"";
static NSURL *_validVerifictationURL;
static NSDate *_validexpirationDate;
static NSUInteger *const _validPollingInterval = 1;

@interface FBSDKDeviceLoginCodeInfo (Testing)

- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger *)pollingInterval;

@end

@interface FBSDKDeviceLoginCodeInfoTests : XCTestCase

@end

@implementation FBSDKDeviceLoginCodeInfoTests

- (void)setUp
{
  [super setUp];
  _validVerifictationURL = [NSURL URLWithString:@"https://www.facebook.com/some/test/url"];
  _validexpirationDate = NSDate.distantFuture;
}

- (void)testCreateValidDeviceLoginCodeShouldSucceed
{
  [self assertCreationSucceedWithIdentifier:_validIdentifier
                                  loginCode:_validLoginCode];
  [self assertCreationSucceedWithIdentifier:_validIdentifier2
                                  loginCode:_validLoginCode2];
  [self assertCreationSucceedWithIdentifier:_validIdentifier3
                                  loginCode:_validLoginCode3];
}

- (void)testCreateWithNilIdentifierAndLoginCode
{
  [self assertCreationSucceedWithIdentifier:nil
                                  loginCode:nil];
}

- (void)testCreateWithEmptyIdentifierAndLoginCode
{
  FBSDKDeviceLoginCodeInfo *deviceLoginCodeInfo = [[FBSDKDeviceLoginCodeInfo alloc] initWithIdentifier:_emptyIdentifier
                                                                                             loginCode:_emptyLoginCode
                                                                                       verificationURL:_validVerifictationURL
                                                                                        expirationDate:_validexpirationDate
                                                                                       pollingInterval:_validPollingInterval];
  XCTAssertNil(deviceLoginCodeInfo.identifier);
  XCTAssertNil(deviceLoginCodeInfo.loginCode);
  XCTAssertEqual(deviceLoginCodeInfo.verificationURL, _validVerifictationURL);
  XCTAssertEqual(deviceLoginCodeInfo.expirationDate, _validexpirationDate);
  XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, _validPollingInterval);
}

- (void)testCreateWithValidStringCastIdentifierAndLoginCode
{
  NSString *stringCastIdentifier = (NSString *)@123;
  NSString *stringCastLoginCode = (NSString *)@123;
  [self assertCreationSucceedWithIdentifier:stringCastIdentifier
                                  loginCode:stringCastLoginCode];
}

- (void)testCreateWithInvalidCast
{
  NSString *invalidIdentifier = (NSString *)NSDictionary.new;
  NSString *invalidLoginCode = (NSString *)NSDictionary.new;
  NSURL *invalidVerificationURL = (NSURL *)NSDictionary.new;
  NSDate *invalidExpirationDate = (NSDate *)NSDictionary.new;
  FBSDKDeviceLoginCodeInfo *deviceLoginCodeInfo = [[FBSDKDeviceLoginCodeInfo alloc] initWithIdentifier:invalidIdentifier
                                                                                             loginCode:invalidLoginCode
                                                                                       verificationURL:invalidVerificationURL
                                                                                        expirationDate:invalidExpirationDate
                                                                                       pollingInterval:_validPollingInterval];
  XCTAssertNil(deviceLoginCodeInfo.identifier);
  XCTAssertNil(deviceLoginCodeInfo.loginCode);
  XCTAssertNil(deviceLoginCodeInfo.verificationURL);
  XCTAssertNil(deviceLoginCodeInfo.expirationDate);
  XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, _validPollingInterval);
}

- (void)assertCreationSucceedWithIdentifier:(NSString *)identifier loginCode:(NSString *)loginCode
{
  FBSDKDeviceLoginCodeInfo *deviceLoginCodeInfo = [[FBSDKDeviceLoginCodeInfo alloc] initWithIdentifier:identifier
                                                                                             loginCode:loginCode
                                                                                       verificationURL:_validVerifictationURL
                                                                                        expirationDate:_validexpirationDate
                                                                                       pollingInterval:_validPollingInterval];
  XCTAssertEqual(deviceLoginCodeInfo.identifier, identifier);
  XCTAssertEqual(deviceLoginCodeInfo.loginCode, loginCode);
  XCTAssertEqual(deviceLoginCodeInfo.verificationURL, _validVerifictationURL);
  XCTAssertEqual(deviceLoginCodeInfo.expirationDate, _validexpirationDate);
  XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, _validPollingInterval);
}

@end
