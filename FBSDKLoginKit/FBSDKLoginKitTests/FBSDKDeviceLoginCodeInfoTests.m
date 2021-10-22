/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h>
#else
 #import "FBSDKDeviceLoginCodeInfo.h"
#endif

static NSString *const _validIdentifier = @"abcd";
static NSString *const _validIdentifier2 = @"123";
static NSString *const _validIdentifier3 = @"123abc";
static NSString *const _validLoginCode = @"abcd";
static NSString *const _validLoginCode2 = @"123";
static NSString *const _validLoginCode3 = @"123abc";
static NSURL *_validVerifictationURL;
static NSDate *_validexpirationDate;
static NSUInteger const _validPollingInterval = 10;

@interface FBSDKDeviceLoginCodeInfo (Testing)

- (instancetype)initWithIdentifier:(NSString *)identifier
                         loginCode:(NSString *)loginCode
                   verificationURL:(NSURL *)verificationURL
                    expirationDate:(NSDate *)expirationDate
                   pollingInterval:(NSUInteger)pollingInterval;

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

- (void)testCreateWithValidStringCastIdentifierAndLoginCode
{
  NSString *stringCastIdentifier = (NSString *)@123;
  NSString *stringCastLoginCode = (NSString *)@123;
  [self assertCreationSucceedWithIdentifier:stringCastIdentifier
                                  loginCode:stringCastLoginCode];
}

- (void)testMinimumPollingInterval
{
  FBSDKDeviceLoginCodeInfo *deviceLoginCodeInfo = [[FBSDKDeviceLoginCodeInfo alloc] initWithIdentifier:_validIdentifier
                                                                                             loginCode:_validLoginCode
                                                                                       verificationURL:_validVerifictationURL
                                                                                        expirationDate:_validexpirationDate
                                                                                       pollingInterval:4];
  XCTAssertEqual(deviceLoginCodeInfo.pollingInterval, 5);
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
