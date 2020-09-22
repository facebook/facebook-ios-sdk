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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#ifdef BUCK
 #import <FBSDKCoreKit/FBSDKCoreKit.h>
#else
@import FBSDKCoreKit;
#endif

#import "FBSDKShareModelTestUtility.h"
#import "FBSDKShareUtility.h"

@interface FBSDKShareUtilityTests : XCTestCase
@end

@implementation FBSDKShareUtilityTests

- (void)testShareLinkContentValidationWithNilValues
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentValidationWithValidValues
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  content.peopleIDs = [FBSDKShareModelTestUtility peopleIDs];
  content.placeID = [FBSDKShareModelTestUtility placeID];
  content.ref = [FBSDKShareModelTestUtility ref];
  XCTAssertNotNil(content.shareUUID);
  NSError *error;
  XCTAssertTrue([content validateWithOptions:FBSDKShareBridgeOptionsDefault error:&error]);
  XCTAssertNil(error);
}

- (void)testShareLinkContentParameters
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = [FBSDKShareModelTestUtility contentURL];
  XCTAssertNotNil(content.shareUUID);
  NSDictionary<NSString *, id> *parameters = [FBSDKShareUtility parametersForShareContent:content bridgeOptions:FBSDKShareBridgeOptionsDefault shouldFailOnDataError:YES];
  XCTAssertEqualObjects(content.contentURL, parameters[@"messenger_link"], @"Incorrect messenger_link param.");
}

@end
