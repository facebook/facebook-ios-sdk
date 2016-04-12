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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKAppInviteContent.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareUtility.h"

@interface FBSDKAppInviteContentTests : XCTestCase
@end

@implementation FBSDKAppInviteContentTests

- (void)testProperties
{
  FBSDKAppInviteContent *content = [[self class] _content];
  XCTAssertEqualObjects(content.appLinkURL, [[self class] _appLinkURL]);
  XCTAssertEqualObjects(content.appInvitePreviewImageURL, [[self class] _appInvitePreviewImageURL]);
}

- (void)testCopy
{
  FBSDKAppInviteContent *content = [[self class] _content];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKAppInviteContent *content = [[self class] _content];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKAppInviteContent *unarchivedObject = [unarchiver decodeObjectOfClass:[FBSDKAppInviteContent class]
                                                                     forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testValidationWithValidContent
{
  FBSDKAppInviteContent *content = [[self class] _content];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilContent
{
  NSError *error;
  XCTAssertNil(error);
  XCTAssertFalse([FBSDKShareUtility validateAppInviteContent:nil error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"content");
}

- (void)testValidationWithNilAppLinkURL
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appInvitePreviewImageURL = [[self class] _appInvitePreviewImageURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"appLinkURL");
}

- (void)testValidationWithNilPreviewImageURL
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilPromotionTextNilPromotionCode
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithValidPromotionCodeNilPromotionText
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  content.promotionCode = @"XSKSK";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionText");
}

- (void)testValidationWithValidPromotionTextNilPromotionCode
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  content.promotionText = @"Some Promo Text";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithInvalidPromotionText
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  content.promotionText = @"_Invalid_promotionText";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionText");
}

- (void)testValidationWithInvalidPromotionCode
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [[self class] _appLinkURL];
  content.promotionText = @"Some promo text";
  content.promotionCode = @"_invalid promo_code";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([FBSDKShareUtility validateAppInviteContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionCode");
}

#pragma mark - Helper Methods

+ (FBSDKAppInviteContent *)_content
{
  FBSDKAppInviteContent *content = [[FBSDKAppInviteContent alloc] init];
  content.appLinkURL = [self _appLinkURL];
  content.appInvitePreviewImageURL = [self _appInvitePreviewImageURL];
  return content;
}

+ (NSURL *)_appLinkURL
{
  return [NSURL URLWithString:@"https://fb.me/1595011414049078"];
}

+ (NSURL *)_appInvitePreviewImageURL
{
  return [NSURL URLWithString:@"https://fbstatic-a.akamaihd.net/rsrc.php/v2/y6/r/YQEGe6GxI_M.png"];
}

@end
