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

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKIDToken.h"

@interface FBSDKIDToken (Testing)

- (void)setClaimsWithEncodedString:(NSString *)encodedClaims;

+ (instancetype)emptyInstance;

@end

@interface FBSDKIDTokenTests : XCTestCase

@end

@implementation FBSDKIDTokenTests

- (void)testDecodeValidClaims
{
  NSDictionary *expectedClaims = @{
    @"sub" : @"1234",
    @"name" : @"Test User",
    @"iss" : @"https://facebook.com/dialog/oauth",
    @"aud" : @"4321",
    @"nonce" : @"some_nonce",
    @"exp" : @1516259022,
    @"email" : @"email@email.com",
    @"picture" : @"https://www.facebook.com/some_picture",
    @"iat" : @1516239022,
  };
  NSData *expectedClaimsData = [FBSDKTypeUtility dataWithJSONObject:expectedClaims options:0 error:nil];
  NSString *encodedClaims = [FBSDKBase64 encodeData:expectedClaimsData];
  FBSDKIDToken *idToken = [FBSDKIDToken emptyInstance];

  [idToken setClaimsWithEncodedString:encodedClaims];
  XCTAssertEqualObjects(idToken.claims, expectedClaims);
}

- (void)testCreateWithInvalidFormatTokenShouldFail
{
  FBSDKIDToken *idToken = [[FBSDKIDToken alloc] initWithTokenString:@"invalid_id_token"];
  XCTAssertNil(idToken);
}

@end
