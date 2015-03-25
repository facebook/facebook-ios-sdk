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
#import <FBSDKShareKit/FBSDKShareOpenGraphObject.h>

#import <XCTest/XCTest.h>

#import "FBSDKShareModelTestUtility.h"

@interface FBSDKShareOpenGraphObjectTests : XCTestCase
@end

@implementation FBSDKShareOpenGraphObjectTests

- (void)testProperties
{
  FBSDKShareOpenGraphObject *object = [FBSDKShareModelTestUtility openGraphObject];
  BOOL boolValue = [[object numberForKey:(NSString *)kFBSDKShareModelTestUtilityOpenGraphBoolValueKey] boolValue];
  XCTAssertEqual(boolValue, [FBSDKShareModelTestUtility openGraphBoolValue]);
  double doubleValue = [[object numberForKey:kFBSDKShareModelTestUtilityOpenGraphDoubleValueKey] doubleValue];
  XCTAssertEqual(doubleValue, [FBSDKShareModelTestUtility openGraphDoubleValue]);
  float floatValue = [[object numberForKey:kFBSDKShareModelTestUtilityOpenGraphFloatValueKey] floatValue];
  XCTAssertEqual(floatValue, [FBSDKShareModelTestUtility openGraphFloatValue]);
  NSInteger integerValue = [[object numberForKey:kFBSDKShareModelTestUtilityOpenGraphIntegerValueKey] integerValue];
  XCTAssertEqual(integerValue, [FBSDKShareModelTestUtility openGraphIntegerValue]);
  NSArray *numberArray = [object arrayForKey:kFBSDKShareModelTestUtilityOpenGraphNumberArrayKey];
  XCTAssertEqualObjects(numberArray, [FBSDKShareModelTestUtility openGraphNumberArray]);
  NSString *string = [object stringForKey:kFBSDKShareModelTestUtilityOpenGraphStringKey];
  XCTAssertEqualObjects(string, [FBSDKShareModelTestUtility openGraphString]);
  NSArray *stringArray = [object arrayForKey:kFBSDKShareModelTestUtilityOpenGraphStringArrayKey];
  XCTAssertEqualObjects(stringArray, [FBSDKShareModelTestUtility openGraphStringArray]);
}

- (void)testCopy
{
  FBSDKShareOpenGraphObject *object = [FBSDKShareModelTestUtility openGraphObject];
  XCTAssertEqualObjects([object copy], object);
}

- (void)testCoding
{
  FBSDKShareOpenGraphObject *object = [FBSDKShareModelTestUtility openGraphObject];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  [unarchiver setRequiresSecureCoding:YES];
  FBSDKShareOpenGraphObject *unarchivedObject = [unarchiver decodeObjectOfClass:[FBSDKShareOpenGraphObject class]
                                                                         forKey:NSKeyedArchiveRootObjectKey];
  XCTAssertEqualObjects(unarchivedObject, object);
}

- (void)testWithInvalidKey
{
  FBSDKShareOpenGraphObject *object = [[FBSDKShareOpenGraphObject alloc] init];
  NSDictionary *properties = @{ [[NSDate alloc] init]: @"test" };
  XCTAssertThrowsSpecificNamed([object parseProperties:properties], NSException, NSInvalidArgumentException);
}

- (void)testWithInvalidValue
{
  FBSDKShareOpenGraphObject *object = [[FBSDKShareOpenGraphObject alloc] init];
  NSDictionary *properties = @{ @"test": [[NSDate alloc] init] };
  XCTAssertThrowsSpecificNamed([object parseProperties:properties], NSException, NSInvalidArgumentException);
}

- (void)testKeyedSubscripting
{
  FBSDKShareOpenGraphObject *object = [FBSDKShareModelTestUtility openGraphObject];
  for (NSString *key in [FBSDKShareModelTestUtility allOpenGraphObjectKeys]) {
    XCTAssertEqual(object[key], object[key]);
  }
}

- (void)testEnumeration
{
  FBSDKShareOpenGraphObject *object = [FBSDKShareModelTestUtility openGraphObject];
  NSMutableSet *expectedKeys = [[NSMutableSet alloc] initWithArray:[FBSDKShareModelTestUtility allOpenGraphObjectKeys]];
  [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    XCTAssertTrue([expectedKeys containsObject:key]);
    XCTAssertEqual(obj, object[key]);
    [expectedKeys removeObject:key];
  }];
  XCTAssertEqual([expectedKeys count], 0u);
}

@end
