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

#import <OCMock/OCMock.h>

#import "FBSDKAppLinkUtility.h"

@interface BFURLAppInvitesTests : XCTestCase
@end

@implementation BFURLAppInvitesTests

- (void)testWithNoPromoCode
{
  NSURL *url = [NSURL URLWithString:@"myapp://somelink/?someparam=somevalue"];
  id promoCode = [FBSDKAppLinkUtility appInvitePromotionCodeFromURL:url];
  XCTAssertNil(promoCode);
}

- (void)testWithPromoCode
{
  NSURL *url = [NSURL URLWithString:@"myapp://somelink/?al_applink_data=%7B%22target_url%22%3Anull%2C%22extras%22%3A%7B%22deeplink_context%22%3A%22%7B%5C%22promo_code%5C%22%3A%5C%22PROMOWORKS%5C%22%7D%22%7D%7D"];
  NSString *promoCode = [FBSDKAppLinkUtility appInvitePromotionCodeFromURL:url];
  XCTAssertNotNil(promoCode);
  XCTAssertEqualObjects(promoCode, @"PROMOWORKS");
}
@end
