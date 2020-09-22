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
#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import "FBSDKShareConstants.h"
#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareVideo.h"

@interface FBSDKShareVideoTests : XCTestCase
@end

@implementation FBSDKShareVideoTests

- (void)testImageProperties
{
  FBSDKShareVideo *video = [FBSDKShareModelTestUtility videoWithPreviewPhoto];
  XCTAssertEqualObjects(video.videoURL, [FBSDKShareModelTestUtility videoURL]);
  XCTAssertEqualObjects(video.previewPhoto, [FBSDKShareModelTestUtility photoWithImageURL]);
}

- (void)testCopy
{
  FBSDKShareVideo *video = [FBSDKShareModelTestUtility video];
  XCTAssertEqualObjects([video copy], video);
}

- (void)testCoding
{
  FBSDKShareVideo *video = [FBSDKShareModelTestUtility videoWithPreviewPhoto];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:video];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
  FBSDKShareVideo *unarchivedVideo = [NSKeyedUnarchiver unarchivedObjectOfClass:[FBSDKShareVideo class] fromData:data error:nil];
#else
  FBSDKShareVideo *unarchivedVideo = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
  XCTAssertEqualObjects(unarchivedVideo, video);
}

@end
