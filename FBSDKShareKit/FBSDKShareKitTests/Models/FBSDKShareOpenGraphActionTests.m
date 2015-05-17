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

#import <FBSDKShareKit/FBSDKShareConstants.h>
#import <FBSDKShareKit/FBSDKShareOpenGraphAction.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"

@interface FBSDKShareOpenGraphActionTests : XCTestCase
@end

@implementation FBSDKShareOpenGraphActionTests

- (void)testProperties
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareModelTestUtility openGraphAction];
  XCTAssertEqualObjects(action.actionType, [FBSDKShareModelTestUtility openGraphActionType]);
  BOOL boolValue = [[action numberForKey:kFBSDKShareModelTestUtilityOpenGraphBoolValueKey] boolValue];
  XCTAssertEqual(boolValue, [FBSDKShareModelTestUtility openGraphBoolValue]);
  double doubleValue = [[action numberForKey:kFBSDKShareModelTestUtilityOpenGraphDoubleValueKey] doubleValue];
  XCTAssertEqual(doubleValue, [FBSDKShareModelTestUtility openGraphDoubleValue]);
  float floatValue = [[action numberForKey:kFBSDKShareModelTestUtilityOpenGraphFloatValueKey] floatValue];
  XCTAssertEqual(floatValue, [FBSDKShareModelTestUtility openGraphFloatValue]);
  NSInteger integerValue = [[action numberForKey:kFBSDKShareModelTestUtilityOpenGraphIntegerValueKey] integerValue];
  XCTAssertEqual(integerValue, [FBSDKShareModelTestUtility openGraphIntegerValue]);
  NSArray *numberArray = [action arrayForKey:kFBSDKShareModelTestUtilityOpenGraphNumberArrayKey];
  XCTAssertEqualObjects(numberArray, [FBSDKShareModelTestUtility openGraphNumberArray]);
  NSString *string = [action stringForKey:kFBSDKShareModelTestUtilityOpenGraphStringKey];
  XCTAssertEqualObjects(string, [FBSDKShareModelTestUtility openGraphString]);
  NSArray *stringArray = [action arrayForKey:kFBSDKShareModelTestUtilityOpenGraphStringArrayKey];
  XCTAssertEqualObjects(stringArray, [FBSDKShareModelTestUtility openGraphStringArray]);
}

- (void)testCopy
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareModelTestUtility openGraphAction];
  XCTAssertEqualObjects([action copy], action);
}

- (void)testCoding
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareModelTestUtility openGraphAction];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:action];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKShareOpenGraphObject *unarchivedAction = [unarchiver decodeObjectOfClass:[FBSDKShareOpenGraphAction class]
                                                                         forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedAction, action);
}

- (void)testWithInvalidKey
{
  FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
  NSDictionary *properties = @{ [[NSDate alloc] init]: @"test" };
  XCTAssertThrowsSpecificNamed([action parseProperties:properties], NSException, NSInvalidArgumentException);
}

- (void)testWithInvalidValue
{
  FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
  NSDictionary *properties = @{ @"test": [[NSDate alloc] init] };
  XCTAssertThrowsSpecificNamed([action parseProperties:properties], NSException, NSInvalidArgumentException);
}

- (void)testKeyedSubscripting
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareModelTestUtility openGraphAction];
  for (NSString *key in [FBSDKShareModelTestUtility allOpenGraphActionKeys]) {
    XCTAssertEqual(action[key], action[key]);
  }
}

- (void)testEnumeration
{
  FBSDKShareOpenGraphAction *action = [FBSDKShareModelTestUtility openGraphAction];
  NSMutableSet *expectedKeys = [[NSMutableSet alloc] initWithArray:[FBSDKShareModelTestUtility allOpenGraphActionKeys]];
  [action enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    XCTAssertTrue([expectedKeys containsObject:key]);
    XCTAssertEqual(obj, action[key]);
    [expectedKeys removeObject:key];
  }];
  XCTAssertEqual([expectedKeys count], 0u);
}

@end
