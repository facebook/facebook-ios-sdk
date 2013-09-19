/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBAppCallTests.h"
#import "FBAppCall+Internal.h"

@implementation FBAppCallTests

-(void) testAppCallFromURL {

    NSURL *testURL = [[NSURL alloc] initWithString:@"scrumptious://link?meal=Chicken&fb_applink_args=%7B%22version%22%3A2%2C%22bridge_args%22%3A%7B%22method%22%3A%22applink%22%7D%2C%22method_args%22%3A%7B%22ref%22%3A%22Tiramisu%22%7D%7D"];
    NSArray *expectedRef = @[@"Tiramisu"];

    NSDictionary *expectedOriginalQueryParameters = @{@"meal": @"Chicken",
                                                      @"fb_applink_args" : @"{\"version\":2,\"bridge_args\":{\"method\":\"applink\"},\"method_args\":{\"ref\":\"Tiramisu\"}}"};
    
    FBAppCall *target = [FBAppCall appCallFromURL:testURL];

    STAssertNotNil(target, @"Failed to create an FBAppCall object");

    STAssertEqualObjects(testURL, target.appLinkData.originalURL, @"Failed to match originalURL");
    STAssertNil(target.appLinkData.actionTypes, @"Failed to correctly parse fb_action_types");
    STAssertTrue([target.appLinkData.ref isEqualToArray:expectedRef], @"Failed to correctly parse fb_ref");
    STAssertTrue([target.appLinkData.originalQueryParameters isEqualToDictionary:expectedOriginalQueryParameters], @"Incorrect originalQueryParameters");

    STAssertNil(target.dialogData, @"Did not expect dialogData to be set.");
    STAssertEqualObjects(@"Tiramisu", target.appLinkData.arguments[@"ref"], @"Failed to parse applinkdata arguments");
}

-(void) testAppCallFromURLWithTapTime {
    
    NSURL *testURL = [[NSURL alloc] initWithString:@"scrumptious://link?meal=Chicken&fb_applink_args=%7B%22version%22%3A2%2C%22bridge_args%22%3A%7B%22method%22%3A%22applink%22%7D%2C%22method_args%22%3A%7B%22ref%22%3A%22Tiramisu%22%7D%7D&fb_click_time_utc=123"];
    NSArray *expectedRef = @[@"Tiramisu"];
    
    NSDictionary *expectedOriginalQueryParameters = @{@"meal": @"Chicken",
                                                      @"fb_applink_args" : @"{\"version\":2,\"bridge_args\":{\"method\":\"applink\"},\"method_args\":{\"ref\":\"Tiramisu\"}}",
                                                      @"fb_click_time_utc":@"123"
                                                      };
    
    FBAppCall *target = [FBAppCall appCallFromURL:testURL];
    
    STAssertNotNil(target, @"Failed to create an FBAppCall object");
    
    STAssertEqualObjects(testURL, target.appLinkData.originalURL, @"Failed to match targetURL");
    STAssertNil(target.appLinkData.actionTypes, @"Failed to correctly parse fb_action_types");
    STAssertTrue([target.appLinkData.ref isEqualToArray:expectedRef], @"Failed to correctly parse fb_ref");
    STAssertTrue([target.appLinkData.originalQueryParameters isEqualToDictionary:expectedOriginalQueryParameters], @"Incorrect originalQueryParameters");
    
    STAssertNil(target.dialogData, @"Did not expect dialogData to be set.");
    STAssertEqualObjects(@"Tiramisu", target.appLinkData.arguments[@"ref"], @"Failed to parse applinkdata arguments");
    STAssertEqualObjects(@"123", target.appLinkData.arguments[@"tap_time_utc"], @"Failed to parse applinkdata arguments (tap_time)");
}

- (void)testAppCallsWithSameIDAreEqual {
    FBAppCall *appCall1 = [[FBAppCall alloc] initWithID:nil
                                          enforceScheme:NO
                                                  appID:nil
                                        urlSchemeSuffix:nil];
    FBAppCall *appCall2 = [[FBAppCall alloc] initWithID:appCall1.ID
                                          enforceScheme:NO
                                                  appID:nil
                                        urlSchemeSuffix:nil];

    assertThat(appCall1, equalTo(appCall2));
    assertThatInteger([appCall1 hash], equalToInteger([appCall2 hash]));
}

- (void)testAppCallsAreNotEqual {
    FBAppCall *appCall1 = [[FBAppCall alloc] initWithID:nil
                                          enforceScheme:NO
                                                  appID:nil
                                        urlSchemeSuffix:nil];
    FBAppCall *appCall2 = [[FBAppCall alloc] initWithID:nil
                                          enforceScheme:NO
                                                  appID:nil
                                        urlSchemeSuffix:nil];

    assertThat(appCall1, isNot(equalTo(appCall2)));
    assertThat(appCall1, isNot(equalTo(nil)));
    assertThat(appCall1, isNot(equalTo(@"string")));
}

@end
