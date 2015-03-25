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

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKShareKit/FBSDKShareOpenGraphContent.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareOpenGraphContentTests : XCTestCase
@end

@implementation FBSDKShareOpenGraphContentTests

- (void)testProperties
{
  FBSDKShareOpenGraphContent *content = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertEqualObjects(content.action, [FBSDKShareModelTestUtility openGraphAction]);
  XCTAssertEqualObjects(content.contentURL, [FBSDKShareModelTestUtility contentURL]);
  XCTAssertEqualObjects(content.peopleIDs, [FBSDKShareModelTestUtility peopleIDs]);
  XCTAssertEqualObjects(content.placeID, [FBSDKShareModelTestUtility placeID]);
  XCTAssertEqualObjects(content.previewPropertyName, [FBSDKShareModelTestUtility previewPropertyName]);
  XCTAssertEqualObjects(content.ref, [FBSDKShareModelTestUtility ref]);
}

- (void)testCopy
{
  FBSDKShareOpenGraphContent *content = [FBSDKShareModelTestUtility openGraphContent];
  XCTAssertEqualObjects([content copy], content);
}

- (void)testCoding
{
  FBSDKShareOpenGraphContent *content = [FBSDKShareModelTestUtility openGraphContent];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:content];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKShareOpenGraphContent *unarchivedObject = [unarchiver decodeObjectOfClass:[FBSDKShareOpenGraphContent class]
                                                                          forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, content);
}

- (void)testValidationWithValidContent
{
  FBSDKShareOpenGraphContent *content = [FBSDKShareModelTestUtility openGraphContent];
  NSError *error;
  XCTAssertNotNil(content);
  XCTAssertNil(error);
  XCTAssertTrue([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNil(error);
}

- (void)testValidationWithNilAction
{
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.previewPropertyName = [FBSDKShareModelTestUtility previewPropertyName];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"action");
}

- (void)testValidationWithNilPreviewPropertyName
{
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [FBSDKShareModelTestUtility openGraphAction];
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], @"previewPropertyName");
}

- (void)testValidationWithInvalidPreviewPropertyName
{
  NSString *previewPropertyName = [[NSUUID UUID] UUIDString];
  FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
  content.action = [FBSDKShareModelTestUtility openGraphAction];
  content.previewPropertyName = previewPropertyName;
  XCTAssertNotNil(content);
  NSError *error;
  XCTAssertFalse([FBSDKShareUtility validateShareContent:content error:&error]);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, FBSDKInvalidArgumentErrorCode);
  XCTAssertEqualObjects(error.userInfo[FBSDKErrorArgumentNameKey], previewPropertyName);
}

@end
