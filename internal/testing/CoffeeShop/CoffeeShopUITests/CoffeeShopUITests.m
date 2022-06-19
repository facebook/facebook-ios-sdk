// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <XCTest/XCTest.h>

@interface CoffeeShopUITests : XCTestCase
{
  XCUIApplication *app;
}
@end

@implementation CoffeeShopUITests

- (void)setUp
{
  [super setUp];
  self.continueAfterFailure = NO;
  app = [[XCUIApplication alloc] init];
  [app launch];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testTriggerAppIndexing
{
  XCUIElement *debugButton = app.navigationBars[@"All Products"].buttons[@"Debug"];
  [debugButton tap];

  XCUIElement *triggerShakeButton = app.sheets[@"Please choose debug function"].buttons[@"Trigger Shake"];
  [self waitForElementToAppear:triggerShakeButton withTimeout:2];
  [triggerShakeButton tap];

  XCUIElement *appIndexingLabel = app.staticTexts[@"App indexing started"];
  [self waitForElementToAppear:appIndexingLabel withTimeout:2];

  NSString *lytroDebugLogs = [CoffeeShopUITests lytroDebugLogs];
  NSString *expectedLogs = [NSString stringWithFormat:@"\n"
                            "fb_mobile_lytro_initialized\n"
                            "fb_mobile_lytro_mapping_loaded\n"
                            "fb_mobile_lytro_gesture_triggered"
  ];
  XCTAssertEqualObjects(lytroDebugLogs, expectedLogs, @"Lytro debug logs not matching");
}

- (void)testViewMatching
{
  [app.tables.staticTexts[@"Coffee 1"] tap];
  [app.buttons[@"Buy"] tap];

  // wait 1 second for matching to complete
  [self wait:2];

  NSString *lytroDebugLogs = [CoffeeShopUITests lytroDebugLogs];
  NSString *expectedLogs = [NSString stringWithFormat:@"\n"
                            "fb_mobile_lytro_initialized\n"
                            "fb_mobile_lytro_mapping_loaded\n"
                            "fb_mobile_lytro_matching_complete\n"
                            "fb_mobile_lytro_matching_complete\n"
                            "fb_mobile_lytro_matching_complete\n"
                            "fb_mobile_lytro_matching_complete\n"
                            "fb_mobile_lytro_matching_complete"
  ];
  XCTAssertEqualObjects(lytroDebugLogs, expectedLogs, @"Lytro debug logs not matching");
}

+ (NSString *)lytroDebugLogs
{
  XCUIElementQuery *windowQuery = [[[XCUIApplication alloc] init] windows];
  return [windowQuery elementBoundByIndex:0].value;
}

- (void)waitForElementToAppear:(XCUIElement *)element withTimeout:(NSTimeInterval)timeout
{
  NSUInteger line = __LINE__;
  NSString *file = [NSString stringWithUTF8String:__FILE__];
  NSPredicate *existsPredicate = [NSPredicate predicateWithFormat:@"exists == true"];

  [self expectationForPredicate:existsPredicate evaluatedWithObject:element handler:nil];

  [self waitForExpectationsWithTimeout:timeout handler:^(NSError *_Nullable error) {
    if (error != nil) {
      NSString *message = [NSString stringWithFormat:@"Failed to find %@ after %f seconds", element, timeout];
      [self recordFailureWithDescription:message inFile:file atLine:line expected:YES];
    }
  }];
}

- (void)wait:(NSUInteger)interval
{
  XCTestExpectation *expectation = [self expectationWithDescription:@"wait"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
    dispatch_get_main_queue(), ^{
      [expectation fulfill];
    });
  [self waitForExpectationsWithTimeout:interval handler:nil];
}

@end
