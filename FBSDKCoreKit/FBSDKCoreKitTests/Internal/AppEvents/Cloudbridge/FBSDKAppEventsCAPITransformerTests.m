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

#import "FBSDKAppEvents.h"
#import "FBSDKAppEventsCAPITransformer.h"

@interface FBSDKAppEventsCAPITransformer (Testing)

+ (NSDictionary<NSString *, NSArray<NSString *> *> *)topLevelTransformations;
+ (NSDictionary<NSString *, NSArray<NSString *> *> *)customEventTransformations;

@end

@interface FBSDKAppEventsCAPITransformerTests : XCTestCase

@end

@implementation FBSDKAppEventsCAPITransformerTests

- (void)setUp
{
  [super setUp];
}

// Check if transformation dictionaries are valid
- (void)testTopLevelTransformationsDictionary
{
  NSDictionary<NSString *, NSArray<NSString *> *> *topLevelTransformations = FBSDKAppEventsCAPITransformer.topLevelTransformations;
  for (NSString *eventKey in topLevelTransformations) {
    if ([eventKey isEqualToString:FBSDKAppEventsUserDataSection]) {
      XCTAssertTrue(topLevelTransformations[eventKey].count == 1);
    } else {
      XCTAssertTrue(topLevelTransformations[eventKey].count == 2);
    }
  }
}

- (void)testCustomEventTransformationsDictionary
{
  NSDictionary<NSString *, NSArray<NSString *> *> *customEventTransformations = FBSDKAppEventsCAPITransformer.customEventTransformations;
  for (NSString *eventKey in customEventTransformations) {
    if ([eventKey isEqualToString:FBSDKAppEventParameterLogTime] || [eventKey isEqualToString:FBSDKAppEventParameterEventName]) {
      XCTAssertTrue(customEventTransformations[eventKey].count == 1);
    } else {
      XCTAssertTrue(customEventTransformations[eventKey].count == 2);
    }
  }
}

- (void)tearDown
{
  [super tearDown];
}

@end
