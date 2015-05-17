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

#import <FBSDKShareKit/FBSDKShareConstants.h>
#import <FBSDKShareKit/FBSDKSharePhoto.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"

@interface FBSDKSharePhotoTests : XCTestCase
@end

@implementation FBSDKSharePhotoTests

- (void)testImageProperties
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImage];
  XCTAssertEqualObjects(photo.image, [FBSDKShareModelTestUtility photoImage]);
  XCTAssertNil(photo.imageURL);
  XCTAssertEqual(photo.userGenerated, [FBSDKShareModelTestUtility photoUserGenerated]);
}

- (void)testImageURLProperties
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertNil(photo.image);
  XCTAssertEqualObjects(photo.imageURL, [FBSDKShareModelTestUtility photoImageURL]);
  XCTAssertEqual(photo.userGenerated, [FBSDKShareModelTestUtility photoUserGenerated]);
}

- (void)testImageCopy
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImage];
  XCTAssertEqualObjects([photo copy], photo);
}

- (void)testImageURLCopy
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertEqualObjects([photo copy], photo);
}

- (void)testInequality
{
  FBSDKSharePhoto *photo1 = [FBSDKShareModelTestUtility photoWithImage];
  FBSDKSharePhoto *photo2 = [FBSDKShareModelTestUtility photoWithImageURL];
  XCTAssertNotEqual([photo1 hash], [photo2 hash]);
  XCTAssertNotEqualObjects(photo1, photo2);
  FBSDKSharePhoto *photo3 = [photo2 copy];
  XCTAssertEqual([photo2 hash], [photo3 hash]);
  XCTAssertEqualObjects(photo2, photo3);
  photo3.userGenerated = !photo2.userGenerated;
  XCTAssertNotEqual([photo2 hash], [photo3 hash]);
  XCTAssertNotEqualObjects(photo2, photo3);
}

- (void)testCoding
{
  FBSDKSharePhoto *photo = [FBSDKShareModelTestUtility photoWithImageURL];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:photo];
  FBSDKSharePhoto *unarchivedPhoto = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  XCTAssertEqualObjects(unarchivedPhoto, photo);
}

- (void)testWithInvalidPhotos
{
  FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
  NSArray *photos = @[
                      [FBSDKShareModelTestUtility photoWithImageURL],
                      [FBSDKShareModelTestUtility photoWithImage],
                      @"my photo",
                      ];
  XCTAssertThrowsSpecificNamed([content setPhotos:photos], NSException, NSInvalidArgumentException);
}

@end
