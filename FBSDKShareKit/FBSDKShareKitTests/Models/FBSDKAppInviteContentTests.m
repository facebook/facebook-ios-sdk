/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <XCTest/XCTest.h>

@import FBSDKCoreKit;

#import "FBSDKAppInviteContent.h"

@interface FBSDKAppInviteContentTests : XCTestCase
@end

@implementation FBSDKAppInviteContentTests

- (void)testProperties
{
  FBSDKAppInviteContent *content = [self.class _content];
  XCTAssertEqualObjects(content.appLinkURL, [self.class _appLinkURL]);
  XCTAssertEqualObjects(content.appInvitePreviewImageURL, [self.class _appInvitePreviewImageURL]);
}

- (void)testCopy
{
  FBSDKAppInviteContent *content = [self.class _content];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKAppInviteContent *content = [self.class _content];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.requiresSecureCoding = YES;
  FBSDKAppInviteContent *unarchivedObject = [unarchiver decodeObjectOfClass:FBSDKAppInviteContent.class
                                                                     forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testValidationWithValidContent
{
  FBSDKAppInviteContent *content = [self.class _content];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilAppLinkURL
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appInvitePreviewImageURL = [self.class _appInvitePreviewImageURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"appLinkURL");
}

- (void)testValidationWithNilPreviewImageURL
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilPromotionTextNilPromotionCode
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithValidPromotionCodeNilPromotionText
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  content.promotionCode = @"XSKSK";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionText");
}

- (void)testValidationWithValidPromotionTextNilPromotionCode
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  content.promotionText = @"Some Promo Text";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithInvalidPromotionText
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  content.promotionText = @"_Invalid_promotionText";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionText");
}

- (void)testValidationWithInvalidPromotionCode
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
  content.appLinkURL = [self.class _appLinkURL];
  content.promotionText = @"Some promo text";
  content.promotionCode = @"_invalid promo_code";
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertFalse([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKErrorInvalidArgument);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"promotionCode");
}

+ (FBSDKAppInviteContent *)_content
{
  FBSDKAppInviteContent *content = [FBSDKAppInviteContent new];
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
