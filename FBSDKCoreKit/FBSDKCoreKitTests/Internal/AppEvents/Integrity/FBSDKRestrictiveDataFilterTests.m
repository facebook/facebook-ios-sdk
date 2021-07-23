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
#import "FBSDKAppEventsState.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKRestrictiveDataFilterManager.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKServerConfigurationManager.h"

@interface FBSDKGraphRequestConnection (RestrictiveDataFilterTesting)

+ (void)resetCanMakeRequests;

@end

typedef void (^FBSDKSKAdNetworkReporterBlock)(void);
@interface FBSDKSKAdNetworkReporter (Testing)
+ (void)_loadConfigurationWithBlock:(FBSDKSKAdNetworkReporterBlock)block;
@end

@interface FBSDKRestrictiveDataFilterManager ()
- (instancetype)initWithServerConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider;
- (NSString *)getMatchedDataTypeWithEventName:(NSString *)eventName
                                     paramKey:(NSString *)paramKey;
@end

@interface FBSDKRestrictiveDataFilterTests : XCTestCase
@property (nonatomic) FBSDKRestrictiveDataFilterManager *restrictiveDataFilterManager;
@end

@implementation FBSDKRestrictiveDataFilterTests

- (void)setUp
{
  [super setUp];

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                   @"test_event_name" : @{
                                                     @"restrictive_param" : @{
                                                       @"first name" : @"6",
                                                       @"last name" : @"7"
                                                     }
                                                   },
                                                   @"restrictive_event_name" : @{
                                                     @"restrictive_param" : @{
                                                       @"dob" : @4
                                                     }
                                                   }
                                                 }];
  self.restrictiveDataFilterManager = [[FBSDKRestrictiveDataFilterManager alloc] initWithServerConfigurationProvider:TestServerConfigurationProvider.class];
  FBSDKServerConfiguration *config = [ServerConfigurationFixtures configWithDictionary:@{ @"restrictiveParams" : params }];

  [TestServerConfigurationProvider setStubbedServerConfiguration:config];
  [self.restrictiveDataFilterManager enable];
}

- (void)testFilterByParams
{
  NSString *eventName = @"restrictive_event_name";
  NSDictionary *parameters = @{@"dob" : @"06-29-2019"};
  NSDictionary *expected = @{@"_restrictedParams" : @"{\"dob\":\"4\"}"};

  XCTAssertEqualObjects(
    [self.restrictiveDataFilterManager processParameters:parameters eventName:eventName],
    expected
  );

  parameters = @{@"test_key" : @66666};

  XCTAssertEqualObjects(
    [self.restrictiveDataFilterManager processParameters:parameters eventName:eventName],
    parameters
  );
}

- (void)testGetMatchedDataTypeByParam
{
  NSString *testEventName = @"test_event_name";
  NSString *type1 = [self.restrictiveDataFilterManager getMatchedDataTypeWithEventName:testEventName paramKey:@"first name"];
  XCTAssertEqualObjects(type1, @"6");

  NSString *type2 = [self.restrictiveDataFilterManager getMatchedDataTypeWithEventName:testEventName paramKey:@"reservation number"];
  XCTAssertNil(type2);
}

- (void)testProcessEventCanHandleAnEmptyArray
{
  NSMutableArray *a = nil;
  XCTAssertNoThrow([self.restrictiveDataFilterManager processEvents:a]);
}

- (void)testProcessEventCanHandleMissingKeys
{
  NSDictionary<NSString *, NSDictionary<NSString *, id> *> *event = @{
    @"some_event" : @{}
  };
  NSMutableArray *eventArray = [[NSMutableArray alloc] initWithObjects:event, nil];

  XCTAssertNoThrow(
    [self.restrictiveDataFilterManager processEvents:eventArray],
    "Data filter manager should be able to process events with missing keys"
  );
}

- (void)testProcessEventDoesntReplaceEventNameIfNotRestricted
{
  NSDictionary<NSString *, NSDictionary<NSString *, id> *> *event = @{
    @"event" : @{
      @"_eventName" : [NSNull null],
    }
  };
  NSMutableArray *eventArray = [[NSMutableArray alloc] initWithObjects:event, nil];

  [self.restrictiveDataFilterManager processEvents:eventArray];

  XCTAssertEqual(
    event[@"event"][@"_eventName"],
    [NSNull null],
    "Non-restricted event names should not be replaced"
  );
}

@end
