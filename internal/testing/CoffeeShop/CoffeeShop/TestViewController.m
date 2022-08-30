// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "TestViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "AAMTestViewController.h"
#import "CodelessTestViewController.h"
// @lint-ignore CLANGTIDY
#import "CoffeeShop-Swift.h"
#import "SuggestedEventsTestViewController.h"
#import "TestSuccessViewController.h"
#import "TestUtils.h"

#define MANUAL_APP_EVENT            @"Manual App Event"
#define CODELESS                    @"Codeless"
#define SUGGESTED_EVENTS            @"Suggested Events"
#define AUTOMATIC_ADVANCED_MATCHING @"Automatic Advanced Matching"
#define MANUAL_ADVANCED_MATCHING    @"Manual Advanced Matching"
#define EVENT_DEACTIVATION          @"Event Deactivation"
#define SENSITIVE_DATA_FILTERING    @"Sensitive Data Filtering"
#define ADDRESS_DETECTION           @"Address Detection"
#define HEALTH_DETECTION            @"Health Detection"
#define CRASH_SHIELD                @"Crash Shield"
#define AEM                         @"Aggregated Events Measurement"
#define CLOUD_BRIDGE                @"Cloud Bridge"
#define E2E_TEST_RUNNER_INFO        @"E2E Test Runner Info"

typedef NS_ENUM(NSUInteger, FBSDKTestFeature) {
  FBSDKTestFeatureManualAppEvent = 0,
  FBSDKTestFeatureCodeless,
  FBSDKTestFeatureSuggestedEvents,
  FBSDKTestFeatureAutomaticAdvancedMatching,
  FBSDKTestFeatureManualAdvancedMatching,
  FBSDKTestFeatureEventDeactivation,
  FBSDKTestFeatureSensitiveDataFiltering,
  FBSDKTestFeatureAddressDetection,
  FBSDKTestFeatureHealthDetection,
  FBSDKTestFeatureCrashShield,
  FBSDKTestFeatureAEM,
  FBSDKTestFeatureCloudBridge,
};

typedef void (^FBSDKFeatureManagerBlock)(BOOL enabled);

@interface FBSDKRestrictiveDataFilterManager (CrashTest)

+ (NSString *)generateCrashForTest;

@end

@implementation FBSDKRestrictiveDataFilterManager (CrashTest)

+ (NSString *)generateCrashForTest
{
  NSMutableArray<NSString *> *a = [NSMutableArray array];
  return a[0];
}

@end

@interface TestViewController ()

@end

@implementation TestViewController
{
  NSMutableArray<NSString *> *items;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  items = [[NSMutableArray alloc] initWithObjects:
           MANUAL_APP_EVENT,
           CODELESS,
           SUGGESTED_EVENTS,
           AUTOMATIC_ADVANCED_MATCHING,
           MANUAL_ADVANCED_MATCHING,
           EVENT_DEACTIVATION,
           SENSITIVE_DATA_FILTERING,
           ADDRESS_DETECTION,
           HEALTH_DETECTION,
           CRASH_SHIELD,
           AEM,
           CLOUD_BRIDGE,
           nil];
  [TestUtils swizzleLogger];

  [self setupE2ETestEnvironmentButton];
}

- (void)setupE2ETestEnvironmentButton
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;
  NSString *isTesting = environment[@"IS_TESTING"];

  if (isTesting) {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"E2E Info"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showE2EInfo)];
    self.navigationItem.rightBarButtonItem = item;
  }
}

- (void)showE2EInfo
{
  E2EInfoViewController *controller = [[E2EInfoViewController alloc] init];
  [self presentViewController:controller animated:true completion:nil];
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UIViewController *codelessVC = [[CodelessTestViewController alloc] init];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  switch (indexPath.row) {
    case FBSDKTestFeatureManualAppEvent:
      [self testManualAppEvent];
      break;
    case FBSDKTestFeatureSuggestedEvents:
      [self testSuggestedEvents];
      break;
    case FBSDKTestFeatureAutomaticAdvancedMatching:
      [self testAutomaticAdvancedMatching];
      break;
    case FBSDKTestFeatureEventDeactivation:
      [self testEventDeactivation];
      break;
    case FBSDKTestFeatureManualAdvancedMatching:
      [self testManualAdvancedMatching];
      break;
    case FBSDKTestFeatureSensitiveDataFiltering:
      [self testSensitiveDataFiltering];
      break;
    case FBSDKTestFeatureCodeless:
      [self.navigationController pushViewController:codelessVC animated:YES];
      break;
    case FBSDKTestFeatureAddressDetection:
      [self testAddressDetection];
      break;
    case FBSDKTestFeatureHealthDetection:
      [self testHealthDetection];
      break;
    case FBSDKTestFeatureCrashShield:
      [self testCrashShield];
      break;
    case FBSDKTestFeatureAEM:
      [self testAEM];
      break;
    case FBSDKTestFeatureCloudBridge:
      [self testCloudBridge];
      break;
    default:
      break;
  }
}

#pragma mark - Test methods

- (void)testManualAppEvent
{
  [FBSDKAppEvents.shared logEvent:@"e2e_test_event"];
  [FBSDKAppEvents.shared flush];
  [TestUtils performBlock:^() {
               NSArray<NSDictionary *> *events = [TestUtils getEvents];
               for (NSDictionary *event in events) {
                 if ([event[EVENT_NAME_KEY] isEqualToString:@"e2e_test_event"]) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to send the event"];
             }
               afterDelay:4];
}

- (void)testSuggestedEvents
{
  SuggestedEventsTestViewController *suggestedEventsTestVC = [[SuggestedEventsTestViewController alloc] init];
  [self.navigationController pushViewController:suggestedEventsTestVC animated:YES];
}

- (void)testAutomaticAdvancedMatching
{
  AAMTestViewController *AAMTestVC = [[AAMTestViewController alloc] init];
  [self.navigationController pushViewController:AAMTestVC animated:YES];
}

- (void)testManualAdvancedMatching
{
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_EMAIL forType:FBSDKAppEventEmail];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_FIRST_NAME forType:FBSDKAppEventFirstName];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_LAST_NAME forType:FBSDKAppEventLastName];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_PHONE forType:FBSDKAppEventPhone];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_DATE_OF_BIRTH forType:FBSDKAppEventDateOfBirth];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_GENDER forType:FBSDKAppEventGender];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_CITY forType:FBSDKAppEventCity];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_STATE forType:FBSDKAppEventState];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_ZIP forType:FBSDKAppEventZip];
  [FBSDKAppEvents.shared setUserData:ADVANCED_MATCHING_EXTERNAL_ID forType:FBSDKAppEventExternalId];

  [FBSDKAppEvents.shared logEvent:@"e2e_test_manual_advanced_matching_event"];
  [FBSDKAppEvents.shared flush];

  [TestUtils performBlock:^() {
               NSArray<NSDictionary<NSString *, NSString *> *> *userDataArrays = [TestUtils getUserData];
               for (NSDictionary<NSString *, NSString *> *userData in userDataArrays) {
                 if ([userData[FBSDKAppEventEmail] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_EMAIL type:FBSDKAppEventEmail]]
                     && [userData[FBSDKAppEventFirstName] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_FIRST_NAME type:FBSDKAppEventFirstName]]
                     && [userData[FBSDKAppEventLastName] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_LAST_NAME type:FBSDKAppEventLastName]]
                     && [userData[FBSDKAppEventPhone] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_PHONE type:FBSDKAppEventPhone]]
                     && [userData[FBSDKAppEventDateOfBirth] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_DATE_OF_BIRTH type:FBSDKAppEventDateOfBirth]]
                     && [userData[FBSDKAppEventGender] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_GENDER type:FBSDKAppEventGender]]
                     && [userData[FBSDKAppEventCity] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_CITY type:FBSDKAppEventCity]]
                     && [userData[FBSDKAppEventState] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_STATE type:FBSDKAppEventState]]
                     && [userData[FBSDKAppEventExternalId] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_EXTERNAL_ID type:FBSDKAppEventExternalId]]
                     && [userData[FBSDKAppEventZip] isEqualToString:[TestUtils encryptData:ADVANCED_MATCHING_ZIP type:FBSDKAppEventZip]]) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to set manual advanced matching"];
             }
               afterDelay:4];
}

- (void)testSensitiveDataFiltering
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"last_name"] = @"li";
  params[@"first name"] = @"fn";
  [TestUtils performBlock:^() {
               [FBSDKAppEvents.shared logEvent:@"manual_initiated_checkout" parameters:params];
               [FBSDKAppEvents.shared flush];
               [TestUtils performBlock:^() {
                            NSArray<NSDictionary *> *events = [TestUtils getEvents];
                            for (NSDictionary *event in events) {
                              NSString *eventName = event[EVENT_NAME_KEY];
                              NSString *restrictedParams = event[RESTRICTED_PARAMS_KEY];
                              if ([eventName isEqualToString:@"manual_initiated_checkout"] && [restrictedParams containsString:@"last_name"] && nil == event[@"last_name"] && [restrictedParams containsString:@"first name"] && nil == event[@"first name"]) {
                                TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                                [self.navigationController pushViewController:vc animated:YES];
                                return;
                              }
                            }
                            [TestUtils showAlert:@"Fail to detect and filter sensitive data"];
                          }
                            afterDelay:4];
             }
               afterDelay:3];
}

- (void)testEventDeactivation
{
  [TestUtils performBlock:^() {
               [FBSDKAppEvents.shared logEvent:@"e2e_test_deactivation_event_param" parameters:@{
                  @"active_parameter" : @"active_parameter_value",
                  @"inactive_parameter" : @"inactive_parameter_value",
                }];
               [FBSDKAppEvents.shared flush];
               [TestUtils performBlock:^() {
                            NSArray<NSDictionary *> *events = [TestUtils getEvents];
                            for (NSDictionary *event in events) {
                              NSString *eventName = event[EVENT_NAME_KEY];
                              if ([eventName isEqualToString:@"e2e_test_deactivation_event_param"] && event[@"active_parameter"] != nil && event[@"inactive_parameter"] == nil) {
                                // For QA Test
                                [FBSDKAppEvents.shared logEvent:@"e2e_test_deactivation_event_qa"];
                                [FBSDKAppEvents.shared logEvent:@"e2e_test_deactivation_event_param_qa" parameters:@{
                                   @"active_parameter" : @"active_parameter_value",
                                   @"inactive_parameter" : @"inactive_parameter_value",
                                 }];

                                TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                                [self.navigationController pushViewController:vc animated:YES];
                                return;
                              }
                            }
                            [TestUtils showAlert:@"Fail to detect and filter deprecated params"];
                          }
                            afterDelay:4];
             }
               afterDelay:3];
}

- (void)testAddressDetection
{
  [FBSDKAppEvents.shared logEvent:@"e2e_test_address_detection" parameters:@{
     @"_empty_string" : @"",
     @"_address" : @"2301 N Highland Ave, Los Angeles, CA 90068"
   }];
  [FBSDKAppEvents.shared flush];
  [TestUtils performBlock:^() {
               NSArray<NSDictionary *> *events = [TestUtils getEvents];
               for (NSDictionary *event in events) {
                 NSString *eventName = event[EVENT_NAME_KEY];
                 NSString *onDeviceParams = event[ON_DEVICE_PARAMS_KEY];
                 if ([eventName isEqualToString:@"e2e_test_address_detection"] && [onDeviceParams containsString:@"_address"] && nil == event[@"_address"]) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to detect and filter address parameter"];
             }
               afterDelay:4];
}

- (void)testHealthDetection
{
  [FBSDKAppEvents.shared logEvent:@"e2e_test_health_detection" parameters:@{
     @"customer_event" : @"\"event\"",
     @"customer_health" : @"heart attack",
   }];
  [FBSDKAppEvents.shared flush];
  [TestUtils performBlock:^() {
               NSArray<NSDictionary *> *events = [TestUtils getEvents];
               for (NSDictionary *event in events) {
                 NSString *eventName = event[EVENT_NAME_KEY];
                 NSString *onDeviceParams = event[ON_DEVICE_PARAMS_KEY];
                 if ([eventName isEqualToString:@"e2e_test_health_detection"] && [onDeviceParams containsString:@"customer_health"] && nil == event[@"customer_health"]) {
                   TestSuccessViewController *vc = [[TestSuccessViewController alloc] init];
                   [self.navigationController pushViewController:vc animated:YES];
                   return;
                 }
               }
               [TestUtils showAlert:@"Fail to detect and filter health parameter"];
             }
               afterDelay:4];
}

- (void)testCrashShield
{
  [TestUtils performBlock:^() {
               NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:@"com.facebook.sdk:FBSDKFeatureManager.FBSDKFeatureRestrictiveDataFiltering"];
               if (!version) {
                 [FBSDKRestrictiveDataFilterManager generateCrashForTest];
               } else {
                 [[FBSDKFeatureManager shared] checkFeature:FBSDKFeatureRestrictiveDataFiltering completionBlock:^(BOOL enabled) {
                   if (enabled) {
                     [FBSDKRestrictiveDataFilterManager generateCrashForTest];
                   } else {
                     TestSuccessViewController *vc = [TestSuccessViewController new];
                     [self.navigationController pushViewController:vc animated:YES];
                     return;
                   }
                 }];
               }
             }
               afterDelay:4];
}

- (void)testAEM
{
  AEMViewController *vc = [AEMViewController new];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)testCloudBridge
{
  CloudBridgeViewController *vc = [CloudBridgeViewController new];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Table View Data source

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  return [items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellId = @"SimpleTableId";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
  [cell.textLabel setText:items[indexPath.row]];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

@end
